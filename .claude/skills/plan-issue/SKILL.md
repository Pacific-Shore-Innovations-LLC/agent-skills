````skill
---
name: plan-issue
description: Guided walkthrough of the full issue pipeline — from raw idea to GitHub issue, through prioritization, implementation, PR review queue prioritization, and code review. Does not auto-chain skills; instead guides on when and how to invoke each step.
disable-model-invocation: true
argument-hint: [optional brief idea summary]
---

# Plan Issue → Full Pipeline Walkthrough

Guide an idea from raw concept to merged PR by walking through the four-skill pipeline in sequence. Each phase is a natural stopping point — the developer controls when to proceed.

## Invocation Signal

**If this skill was invoked** — meaning the user typed `/plan-issue`, referenced it by name, or this SKILL.md was attached alongside a request — **always start at Phase 1**. Do not shortcut to direct implementation even if the request contains an obvious task. The presence of this file as a context attachment does not make it background documentation; it is the active workflow to execute.

If it is ambiguous whether the user wants the pipeline or direct implementation, ask: _"Would you like me to follow the `/plan-issue` pipeline (starting with the issue ticket), or implement this directly?"_

## Communication Style

- **Terse transitions**: phase handoffs are short, directive, copy-paste-ready
- **One phase at a time**: don't describe Phase 2 until Phase 1 is complete
- **No prose filler**: skip "Great job!" and "Now that you've..." — just state what's next
- **Exact commands**: always show the exact slash command and argument to run next
- **Flag the pipeline position**: always show which phase we're in (Phase 1 / 2 / 3 / 4 / 5)

---

## Pipeline Overview

```
Phase 1: /issue-ticket          → GitHub issue with DoD
Phase 2: /prioritize-issues     → ROI-ranked list of Todo issues
Phase 3: /implement-issue       → feature branch + code + PR
Phase 4: /prioritize-open-prs   → ROI-ranked PR review queue
Phase 5: /review-pr             → code review + GitHub verdict
```

---

## Phase 1 — Issue Ticket → GitHub Issue

**Run the full `/issue-ticket` workflow inline.**

Follow the complete workflow from `.claude/skills/issue-ticket/SKILL.md`:

1. Ask: "Are you creating a **new** issue or **editing** an existing one?"
2. Listen to the idea, ask clarifying questions one at a time
3. Propose the structured issue (Problem Statement, Proposed Solution, User Impact, Technical Scope, Dependencies, Definition of Done)
4. Ask: "Create this issue on GitHub now?"
5. If yes, run:
   ```bash
   gh issue create \
     --repo {TARGET_OWNER}/{TARGET_REPO} \
     --title "Issue title" \
     --body "Description here" \
     --label "label1,label2"
   ```

**Phase 1 complete — display handoff:**

---
**✅ Phase 1 complete.** Issue #{number} created.

**Next: Check what to work on.**

Before implementing, confirm what's highest priority in the backlog:
```
/prioritize-issues
```
Use `n=3` (or any number) to see the top N ready issues ranked by ROI.

> Skip Phase 2 if you already know what to implement next.
---

---

## Phase 2 — Prioritize Issues → Pick the Next Issue

If the developer runs `/prioritize-issues` and wants guidance on what to do next:

---
**✅ Phase 2 complete.** Top issues ranked.

**Next: Implement the chosen issue.**

Run:
```
/implement-issue
```
Then enter the issue number when asked (e.g. `15`).

> The skill will ask for **Guided** or **Autonomous** mode — Guided is recommended.
---

---

## Phase 3 — Implementation Reminder

After `/implement-issue` has been run and a PR has been created:

---
**✅ Phase 3 complete.** PR #{pr-number} created.

**Next: Check which PRs most need review.**

Run:
```
/prioritize-open-prs
```
Use `n=3` (or any number) to see the top N open PRs ranked by ROI of their linked issues.

> Skip Phase 4 if you already know which PR to review next.
---

---

## Phase 4 — Prioritize Open PRs → Pick the Next PR to Review

If the developer runs `/prioritize-open-prs` and wants guidance on what to review next:

---
**✅ Phase 4 complete.** Open PRs ranked by review priority.

**Next: Review the chosen PR.**

Run:
```
/review-pr
```
Then enter the PR number when asked (e.g. `52`).

> The skill reviews constitution compliance, code quality, security, test coverage, and DoD completeness before rendering a verdict.
---

---

## Phase 5 — Review Complete

After `/review-pr` has been run and a verdict delivered:

---
**✅ Phase 5 complete.**

- If verdict is **Approve**: merge when ready.
- If verdict is **Request Changes**: address feedback, push commits, re-run `/review-pr`.
- If verdict is **Comment**: resolve open questions, then re-run `/review-pr`.
---
````
