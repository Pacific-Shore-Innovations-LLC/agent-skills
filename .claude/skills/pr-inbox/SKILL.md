---
name: pr-inbox
description: Unified ROI-ranked action queue of reviewed PRs across all workspace repos. Shows your own PRs with all review states (scope=mine, default), or all approved-and-ready PRs regardless of author (scope=all). Tells you exactly what to do next — merge or address feedback.
disable-model-invocation: true
argument-hint: [n=[number]] [scope=mine|all] [repo=[repo-or-owner/repo]]
---

# PR Inbox → Reviewed PR Action Queue

Surface reviewed pull requests ranked by ROI and tell you exactly what action to take on each — merge, address feedback, or defer.

## Communication Style

- **Action-first output**: each entry leads with the verdict and the action, not background
- **No preamble**: output starts immediately with the ranked list — skip "Here's what I found"
- **Terse summaries**: one sentence per PR explaining why this rank and what specifically needs doing
- **Exact commands**: NEXT ACTION always shows a copy-paste-ready command
- **Sections by verdict** (scope=mine only): Approved first, then Changes Requested, then Commented

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
- `scope` — whose PRs to show:
  - `mine` (default): only PRs authored by `@me`; all review states shown
  - `all`: all open PRs regardless of author; filtered to `reviewDecision: APPROVED` only
- Both arguments are optional. Example: `/pr-inbox n=5 scope=all`

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

**scope=all:**
```bash
gh pr list \
  --repo {OWNER}/{REPO} \
  --state open \
  --json number,title,body,labels,reviewDecision,reviews,author,changedFiles \
  --limit 50
```
Filter to PRs where `reviewDecision == "APPROVED"` only.

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

Use the same three-dimension formula as `prioritize-open-prs`.

### Business Value (1–10)

| Signal | Score |
|---|---|
| P1/blocker/SLA/data-loss | 10 |
| P2/customer-facing revenue feature | 8–9 |
| P3/internal tool, DX improvement | 5–7 |
| P4/polish, nice-to-have | 2–4 |

**Label boosts** (+1–2 each, capped at 10): `mvp`, `high-priority`, `critical`, `security`, `hotfix`

### Risk (1–10)

| Signal | Score |
|---|---|
| Architecture spike, unknown territory | 10 |
| Multi-service change, data migration | 8–9 |
| Complex but well-understood (changedFiles > 20) | 5–7 |
| Small, isolated, well-scoped (changedFiles ≤ 5) | 2–4 |

### Dependencies (1–10)

| Signal | Score |
|---|---|
| Blocked by external team or unresolved external | 10 |
| Body references unresolved `depends on #N` / open PR | 7–9 |
| Some sequencing implied but manageable | 4–6 |
| Self-contained, no blockers | 1–3 |

### Formula

```
ROI Score = Value / (Risk + Dependencies)
```

Round to one decimal place. Higher is better.

---

## Step 5 — Rank and Output

Sort all PRs across all repos by ROI descending.

**scope=mine**: split into three sections — Approved, Changes Requested, Commented — each sorted by ROI within the section. Show up to `n` entries per section.

**scope=all**: single unified list (all are Approved). Show top `n`.

---

## Output Format

### scope=mine

```
PR INBOX — [REPOS] — scope: mine

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
    Review: 🔄 Changes requested by {reviewer}
    Feedback: {one-sentence summary of what was asked for}
    NEXT ACTION: Address "{specific feedback}" → push commits → re-run /review-pr → {pr}

── 💬 COMMENTED ──────────────────────────────────

#1. [{OWNER}/{REPO}] PR #{pr}: {title}
    Author: @{author} | ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Review: 💬 Comment from {reviewer}
    Thread: {one-sentence summary of open question}
    NEXT ACTION: Resolve "{open question}" → reply or push → re-run /review-pr → {pr}

─────────────────────────────────────
NEXT STEPS:
gh pr merge {pr} --repo {OWNER}/{REPO} --squash   ← highest ROI approved
gh pr merge {pr} --repo {OWNER}/{REPO} --squash   ← next
❌ Defer: [{REPO}] PR #{pr} — {one-phrase reason}
─────────────────────────────────────
```

### scope=all

```
PR INBOX — [REPOS] — scope: all (approved only)

#1. [{OWNER}/{REPO}] PR #{pr}: {title}
    Author: @{author} | ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Review: ✅ Approved by {reviewer}
    Why: {one-sentence rationale}
    NEXT ACTION: gh pr merge {pr} --repo {OWNER}/{REPO} --squash

#2. ...

─────────────────────────────────────
NEXT STEPS:
gh pr merge {pr} --repo {OWNER}/{REPO} --squash   ← start here
gh pr merge {pr} --repo {OWNER}/{REPO} --squash   ← next
─────────────────────────────────────
```

**Rules:**
- `[{OWNER}/{REPO}]` prefix is always shown when multiple repos are in the output
- If only one repo, omit the prefix to reduce noise
- If no reviewed PRs match in any repo: `Note: no reviewed PRs found matching scope={scope} across {repos}.`
- Draft PRs are always excluded

---

## Guardrails

- **Never** merge, push, or modify any PR without explicit user confirmation
- **Never** post review comments or edit PR descriptions
- **Never** include closed or merged PRs
- **Never** include draft PRs
- **scope=all** must only show `APPROVED` PRs — never surface Changes Requested or Commented PRs for other authors
- **Always** include a NEXT STEPS block even if all PRs are deferred
- **Always** show the full `gh pr merge` command — never abbreviate it
