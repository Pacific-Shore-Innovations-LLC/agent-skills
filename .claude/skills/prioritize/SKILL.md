````skill
---
name: prioritize
description: Query the GitHub project board for Todo issues, compute ROI scores, and return a ranked list of N tickets with rationale and /implement-issue next-step commands.
disable-model-invocation: true
argument-hint: n=[number]
---

# Prioritize Backlog → Ranked Issue List

Query open Todo issues from the GitHub project board, score each by ROI, and return a ranked list with next-step commands.

## Communication Style

- **Analytical and concise**: lead with the ranked list — no preamble, no "Here's what I found"
- **Numbers first**: ROI score, Value, Risk, Deps on the same line as the issue title
- **One-sentence rationale**: the "Why" for each ticket is a single sentence — no elaboration
- **Actionable output**: NEXT STEPS block is always the final section, always actionable
- **Terse on ties**: if two issues have equal ROI, note it briefly and move on

---

## Workflow

**Step 1 — Parse the argument.**
Read `n` from the invocation (e.g. `/prioritize n=3`). Default to `n=5` if not provided.

**Step 2 — Discover project context.**

Resolve the project board number for the target org/repo:
```bash
gh project list --owner {TARGET_OWNER} --format json
```

Select the project whose title most closely matches `{TARGET_REPO}`. If no match, use the first project. Record as `{PROJECT_NUMBER}`.

**Step 3 — Fetch Todo issues from the project board (two-step).**

Fetch all project items:
```bash
gh project item-list {PROJECT_NUMBER} --owner {TARGET_OWNER} --format json
```

Filter for items where `status` = `"Todo"` and `type` = `"ISSUE"`. Extract issue numbers.

Then fetch scoring inputs for each Todo issue:
```bash
gh issue view {number} --repo {TARGET_OWNER}/{TARGET_REPO} --json number,title,body,labels,state
```

Discard any issues that are closed or have a state other than open.

**Step 4 — Score each issue.**

Compute three dimensions per issue using the issue title, labels, and body (DoD complexity, dependency references, linked issues).

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

Sort issues descending by ROI Score. Return the top N. If fewer than N Todo issues exist, return all available and note the shortfall.

---

## Output Format

```
TOP [N] READY ISSUES — {TARGET_REPO} Backlog

#1. {Issue Title} (#{number})
ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
Why: {one-sentence rationale}

#2. {Issue Title} (#{number})
ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
Why: {one-sentence rationale}

...

─────────────────────────────────────
NEXT STEPS:
✅ /implement-issue → {number}   ← start here
✅ /implement-issue → {number}   ← next
❌ Defer: {Issue Title} (#{number}) — {one-phrase reason}
─────────────────────────────────────
```

Rules:
- Show ✅ for each ranked issue that is ready to implement
- Show ❌ Defer for any issue in the ranked list with an unresolved blocker or spike needed
- Do not show issues outside the ranked list in NEXT STEPS
- If fewer than N issues are available: `Note: only {k} Todo issues found — showing all {k}.`

---

## Guardrails

- **Never** create issues, branches, or pull requests
- **Never** recommend issues that are not in Todo status on the project board
- **Never** recommend issues explicitly blocked by an unresolved dependency (mark ❌ Defer instead)
- **Always** use `/implement-issue → {number}` syntax in NEXT STEPS (number, not title)
- **Always** include a NEXT STEPS block, even if all issues are deferred

---

## Example

**Input:**
```
/prioritize n=3
```

**Expected output:**
```
TOP 3 READY ISSUES — utilityiou Backlog

#1. Device Management for Residential Properties (#35)
ROI: 1.5 | Value: 9  Risk: 4  Deps: 2
Why: Low-risk CRUD work that unblocks the higher-complexity device data migration (#36).

#2. Migrate Device Data Upload to Device-Based Model (#36)
ROI: 1.3 | Value: 10  Risk: 5  Deps: 3
Why: Fixes a known architectural seam; max business value once #35 lands.

#3. Complete Bill Review & Confirmation Flow (#16)
ROI: 1.0 | Value: 10  Risk: 5  Deps: 5
Why: Closes the landlord happy path and gates tenant report delivery.

─────────────────────────────────────
NEXT STEPS:
✅ /implement-issue → 35   ← start here
✅ /implement-issue → 36   ← next
✅ /implement-issue → 16
─────────────────────────────────────
```
````
