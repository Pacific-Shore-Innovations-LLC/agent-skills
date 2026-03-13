````skill
---
name: prioritize-open-prs
description: Query open PRs that have linked issues, compute ROI scores on the linked issues, and return a ranked list of N PRs to review — ordered by business value to guide where to invoke /review-pr next.
disable-model-invocation: true
argument-hint: n=[number]
---

# Prioritize Open PRs → Ranked Review Queue

Find open pull requests with linked issues, score each linked issue by ROI, and return a ranked list of PRs to prioritize for code review — with next-step `/review-pr` commands ready to copy.

## Communication Style

- **Analytical and concise**: lead with the ranked list — no preamble, no "Here's what I found"
- **PR-first output**: PR number is the primary identifier; linked issue number is secondary
- **Numbers first**: ROI score, Value, Risk, Deps on the same line as the PR/issue title
- **One-sentence rationale**: the "Why" for each entry is a single sentence
- **Actionable output**: NEXT STEPS block is always the final section, always actionable

---

## Workflow

**Step 1 — Parse the argument.**
Read `n` from the invocation (e.g. `/prioritize-open-prs n=3`). Default to `n=5` if not provided.

**Step 2 — Find issues linked to open PRs.**

```bash
gh issue list \
  --search "linked:pr" \
  --repo {TARGET_OWNER}/{TARGET_REPO} \
  --state open \
  --json number,title,body,labels,state \
  --limit 50
```

This returns issues that have at least one linked pull request. Discard any closed issues.

**Step 3 — Resolve the linked PR number for each issue.**

For each issue returned in Step 2:

```bash
gh issue view {number} \
  --repo {TARGET_OWNER}/{TARGET_REPO} \
  --json number,title,body,labels,linkedPullRequests
```

Extract `linkedPullRequests[].number` and `linkedPullRequests[].state`. Keep only issues where at least one linked PR has `state = "OPEN"`. Record the open PR number(s) alongside the issue.

If an issue has multiple open linked PRs, create a separate scored entry for each PR.

**Step 4 — Score each issue by ROI.**

Use the same three-dimension scoring as `/prioritize-issues`, applied to the linked issue's title, labels, and body:

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
| Complex but well-understood | 5–7 |
| Small, isolated, well-scoped | 2–4 |

Adjust upward if DoD has many checklist items or cross-cutting concerns.

### Dependencies (1–10)

| Signal | Score |
|---|---|
| Blocked by external team or unresolved external | 10 |
| Linked unresolved issues in DoD or body | 7–9 |
| Some sequencing implied but manageable | 4–6 |
| Self-contained, no blockers | 1–3 |

### Formula

```
ROI Score = Value / (Risk + Dependencies)
```

Round to one decimal place. Higher is better.

**Step 5 — Rank and output.**

Sort descending by ROI Score. Return the top N. If fewer than N open PRs with linked issues exist, return all available and note the shortfall.

---

## Output Format

```
TOP [N] PRS AWAITING REVIEW — {TARGET_REPO}

#1. PR #{pr-number}: {PR Title or Issue Title}
    Linked Issue: #{issue-number}
    ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Why: {one-sentence rationale}

#2. PR #{pr-number}: {PR Title or Issue Title}
    Linked Issue: #{issue-number}
    ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Why: {one-sentence rationale}

...

─────────────────────────────────────
NEXT STEPS:
✅ /review-pr → {pr-number}   ← start here
✅ /review-pr → {pr-number}   ← next
❌ Defer: PR #{pr-number} (Issue #{issue-number}) — {one-phrase reason}
─────────────────────────────────────
```

Rules:
- **PR number is always the primary identifier** in both the ranked list and NEXT STEPS
- Show `✅` for each PR ready for review
- Show `❌ Defer` for any PR whose linked issue has an unresolved blocker
- If a PR title is not yet available, use the linked issue title
- If no open PRs with linked issues are found: `Note: no open PRs with linked issues found in {TARGET_REPO}.`

---

## Guardrails

- **Never** create issues, branches, or pull requests
- **Never** recommend already-merged or closed PRs
- **Never** score issues not linked to an open PR
- **Always** use `/review-pr → {pr-number}` syntax in NEXT STEPS (PR number, not issue number)
- **Always** include a NEXT STEPS block, even if all PRs are deferred

---

## Example

**Input:**
```
/prioritize-open-prs n=3
```

**Expected output:**
```
TOP 3 PRS AWAITING REVIEW — utilityiou

#1. PR #52: Add Device Management CRUD Endpoints
    Linked Issue: #35
    ROI: 1.5 | Value: 9  Risk: 4  Deps: 2
    Why: Merging this unblocks device data migration (#36) and closes the landlord setup happy path.

#2. PR #55: Complete Bill Review & Confirmation Flow
    Linked Issue: #16
    ROI: 1.2 | Value: 10  Risk: 5  Deps: 3
    Why: Highest business value in the queue; gates tenant report delivery for beta users.

#3. PR #58: Fix TOU Rate Boundary Calculation
    Linked Issue: #47
    ROI: 0.9 | Value: 8  Risk: 5  Deps: 4
    Why: Correctness fix with moderate complexity; safe to review after #52.

─────────────────────────────────────
NEXT STEPS:
✅ /review-pr → 52   ← start here
✅ /review-pr → 55   ← next
✅ /review-pr → 58
─────────────────────────────────────
```
````
