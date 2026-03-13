````skill
---
name: pr-triage
description: Unified ROI-ranked PR action queue across all workspace repos. Shows your own PRs with all review states (scope=mine, default), all open PRs awaiting first review (scope=team), or PRs with changes-requested awaiting rework (scope=rework). Tells you exactly what to do next — merge, address feedback, assign a reviewer, or implement rework. Also emits structured MCP output with suggested_next_tool for autonomous pipeline agents.
disable-model-invocation: true
argument-hint: [n=[number]] [scope=mine|team|rework] [repo=[repo-or-owner/repo]]
---

# PR Triage → Unified PR Action Queue

Surface pull requests ranked by ROI and tell you exactly what action to take on each — merge, address feedback, assign a reviewer, or implement rework. Works for both human-interactive sessions and autonomous pipeline agents.

## Communication Style

- **Action-first output**: each entry leads with the verdict and the action, not background
- **No preamble**: output starts immediately with the ranked list — skip "Here's what I found"
- **Terse summaries**: one sentence per PR explaining why this rank and what specifically needs doing
- **Exact commands**: NEXT ACTION always shows a copy-paste-ready command
- **Sections by verdict** (scope=mine only): Approved first, then Changes Requested, then Commented
- **scope=team**: single ranked list of PRs awaiting first review — action is always `/review-pr`
- **scope=rework**: single ranked list of changes-requested PRs — action is always `/implement-rework-pr`

---

## Step 0 — Resolve Target Repos

Discover all repos to query using this priority order:

1. If `repo=owner/repo` or `repo=shortname` was passed as an argument, use only that repo.
2. Otherwise, inspect the VS Code multi-root workspace folders visible in context. For each folder that is a git repository, resolve its `owner/repo`:
   ```bash
   gh repo view --json nameWithOwner --jq .nameWithOwner
   ```
   Run this from each workspace folder root.
3. If only one repo is detectable and no `repo=` was passed, use `{TARGET_OWNER}/{TARGET_REPO}` silently.

Collect all resolved repos as `REPO_LIST` for all subsequent steps.

---

## Step 1 — Parse Arguments

- `n` — number of PRs to return per section. Default: `10`.
- `scope` — which PRs to show:
  - `mine` (default): only PRs authored by `@me`; all review states shown; grouped by verdict
  - `team`: all open PRs regardless of author awaiting first review (`reviewDecision` is null/empty); full ROI ranking; for autonomous agents this is the "what needs a reviewer?" signal
  - `rework`: all open PRs regardless of author where `reviewDecision == "CHANGES_REQUESTED"`; ROI-ranked by rework urgency; for autonomous agents this is the `implement-rework-pr` queue
- All arguments are optional. Example: `/pr-triage n=5 scope=rework`

---

## Step 2 — Fetch PRs

For each repo in `REPO_LIST`, run the appropriate fetch:

**scope=mine:**
```bash
gh pr list \
  --repo {OWNER}/{REPO} \
  --author "@me" \
  --state open \
  --json number,title,body,labels,reviewDecision,reviews,author,changedFiles \
  --limit 50
```
Filter to PRs where `reviews` array is non-empty (at least one review has occurred).
Discard PRs where `reviewDecision` is null and `reviews` is empty.

**scope=team:**
```bash
gh pr list \
  --repo {OWNER}/{REPO} \
  --state open \
  --json number,title,body,labels,reviewDecision,reviews,author,changedFiles \
  --limit 50
```
Filter to PRs where `reviewDecision` is null or empty AND `reviews` is empty (not yet reviewed).

**scope=rework:**
```bash
gh pr list \
  --repo {OWNER}/{REPO} \
  --state open \
  --json number,title,body,labels,reviewDecision,reviews,author,changedFiles \
  --limit 50
```
Filter to PRs where `reviewDecision == "CHANGES_REQUESTED"`.

Tag each PR record with its source repo (`OWNER/REPO`) for the unified output.

---

## Step 3 — Resolve Linked Issues for Scoring

For each PR, check the body for a linked issue reference (`Closes #N`, `Fixes #N`, `Resolves #N`). If found:

```bash
gh issue view {N} --repo {OWNER}/{REPO} --json number,title,body,labels
```

Use the linked issue's labels and body for ROI scoring (same signal source as `prioritize-open-prs`).
If no linked issue is found, score from the PR's own body and labels directly.

---

## Step 4 — Score Each PR by ROI

Scoring dimensions differ by scope to reflect what each group optimises for.

### Business Value (1–10) — all scopes

| Signal | Score |
|---|---|
| P1/blocker/SLA/data-loss | 10 |
| P2/customer-facing revenue feature | 8–9 |
| P3/internal tool, DX improvement | 5–7 |
| P4/polish, nice-to-have | 2–4 |

**Label boosts** (+1–2 each, capped at 10): `mvp`, `high-priority`, `critical`, `security`, `hotfix`

### Risk (1–10) — all scopes

| Signal | Score |
|---|---|
| Architecture spike, unknown territory | 10 |
| Multi-service change, data migration | 8–9 |
| Complex but well-understood (changedFiles > 20) | 5–7 |
| Small, isolated, well-scoped (changedFiles ≤ 5) | 2–4 |

### Dependencies (1–10) — all scopes

| Signal | Score |
|---|---|
| Blocked by external team or unresolved external | 10 |
| Body references unresolved `depends on #N` / open PR | 7–9 |
| Some sequencing implied but manageable | 4–6 |
| Self-contained, no blockers | 1–3 |

### Urgency boost — scope=rework only

For `scope=rework`, add an urgency multiplier based on time since changes were requested:
- < 1 day: no boost
- 1–3 days: Value +1
- 4–7 days: Value +2
- > 7 days: Value +3 (capped at 10)

Also count `blocking_issues_count` from the most recent review thread: fewer blocking issues = higher throughput priority (+1 to Value if ≤ 2 blocking issues).

### Formula

```
ROI Score = Value / (Risk + Dependencies)
```

Round to one decimal place. Higher is better.

---

## Step 5 — Rank and Output

Sort all PRs across all repos by ROI descending within each section.

**scope=mine**: split into three sections — Approved, Changes Requested, Commented — each sorted by ROI within the section. Show up to `n` entries per section.

**scope=team**: single unified list (all awaiting first review). Show top `n`.

**scope=rework**: single unified list (all changes-requested). Show top `n`. Include `blocking_issues_count` per entry.

### MCP Structured Output (autonomous pipeline agents)

When invoked as an MCP tool, each PR entry in the JSON response includes `suggested_next_tool` to enable `plan-feature` pipeline graph execution without requiring the agent to parse prose:

```json
{
  "ranked_prs": [
    {
      "pr_number": 17,
      "repo": "Pacific-Shore-Innovations-LLC/utilityiou",
      "title": "...",
      "score": 9.1,
      "score_breakdown": { "value": 8, "risk": 3, "deps": 2 },
      "verdict": "changes_requested",
      "blocking_issues_count": 3,
      "days_since_review": 2,
      "suggested_next_tool": "implement_rework_pr",
      "url": "https://github.com/..."
    }
  ],
  "scope": "rework",
  "repos_queried": ["Pacific-Shore-Innovations-LLC/utilityiou"]
}
```

`suggested_next_tool` values by verdict:
- `approved` → `null` (hard gate — merge requires human confirmation)
- `changes_requested` → `implement_rework_pr`
- awaiting first review (scope=team) → `review_pr`
- `commented` → `review_pr`

---

## Output Format

### scope=mine

```
PR TRIAGE — [REPOS] — scope: mine

── ✅ APPROVED (ready to merge) ──────────────────

#1. [{OWNER}/{REPO}] PR #{pr}: {title}
    Author: @{author} | ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Review: ✅ Approved by {reviewer}
    Why: {one-sentence rationale}
    NEXT ACTION: gh pr merge {pr} --repo {OWNER}/{REPO} --squash

#2. ...

── 🔄 CHANGES REQUESTED ──────────────────────────

#1. [{OWNER}/{REPO}] PR #{pr}: {title}
    Author: @{author} | ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Review: 🔄 Changes requested by {reviewer} | Blocking issues: {N}
    Feedback: {one-sentence summary of what was asked for}
    NEXT ACTION: Address "{specific feedback}" → push commits → re-run /review-pr {pr}

── 💬 COMMENTED ──────────────────────────────────

#1. [{OWNER}/{REPO}] PR #{pr}: {title}
    Author: @{author} | ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Review: 💬 Comment from {reviewer}
    Thread: {one-sentence summary of open question}
    NEXT ACTION: Resolve "{open question}" → reply or push → re-run /review-pr {pr}

─────────────────────────────────────
NEXT STEPS:
gh pr merge {pr} --repo {OWNER}/{REPO} --squash   ← highest ROI approved
/review-pr {pr} repo={OWNER}/{REPO}               ← address changes requested
─────────────────────────────────────
```

### scope=team

```
PR TRIAGE — [REPOS] — scope: team (awaiting first review)

#1. [{OWNER}/{REPO}] PR #{pr}: {title}
    Author: @{author} | ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Status: 🔍 Awaiting first review
    Why: {one-sentence rationale}
    NEXT ACTION: /review-pr {pr} repo={OWNER}/{REPO}

#2. ...

─────────────────────────────────────
NEXT STEPS:
/review-pr {pr} repo={OWNER}/{REPO}   ← start here
/review-pr {pr} repo={OWNER}/{REPO}   ← next
─────────────────────────────────────
```

### scope=rework

```
PR TRIAGE — [REPOS] — scope: rework (changes requested)

#1. [{OWNER}/{REPO}] PR #{pr}: {title}
    Author: @{author} | ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Review: 🔄 Changes requested by {reviewer} | Blocking issues: {N} | {D} days ago
    Feedback: {one-sentence summary of what was asked for}
    NEXT ACTION: /implement-rework-pr {pr} repo={OWNER}/{REPO}

#2. ...

─────────────────────────────────────
NEXT STEPS:
/implement-rework-pr {pr} repo={OWNER}/{REPO}   ← highest urgency
/implement-rework-pr {pr} repo={OWNER}/{REPO}   ← next
─────────────────────────────────────
```

**Rules:**
- `[{OWNER}/{REPO}]` prefix is always shown when multiple repos are in the output
- If only one repo, omit the prefix to reduce noise
- If no PRs match in any repo: `Note: no PRs found matching scope={scope} across {repos}.`
- Draft PRs are always excluded

---

## Guardrails

- **Never** merge, push, or modify any PR without explicit user confirmation
- **Never** post review comments or edit PR descriptions
- **Never** include closed or merged PRs
- **Never** include draft PRs
- **MCP `suggested_next_tool`** for `approved` is always `null` — autonomous agents must not merge without a hard-gate human confirmation step
- **Always** include a NEXT STEPS block even if all PRs are deferred
- **Always** show the full `gh pr merge` command — never abbreviate it
````
