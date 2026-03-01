````skill
---
name: plan-issue
description: Guided walkthrough of the full issue pipeline — from raw idea to GitHub issue, through prioritization, implementation, and PR review. Does not auto-chain skills; instead guides on when and how to invoke each step.
disable-model-invocation: true
argument-hint: [optional brief idea summary]
---

# Plan Issue → Full Pipeline Walkthrough

Guide an idea from raw concept to merged PR by walking through the four-skill pipeline in sequence. Each phase is a natural stopping point — the developer controls when to proceed.

## Communication Style

- **Terse transitions**: phase handoffs are short, directive, copy-paste-ready
- **One phase at a time**: don't describe Phase 2 until Phase 1 is complete
- **No prose filler**: skip "Great job!" and "Now that you've..." — just state what's next
- **Exact commands**: always show the exact slash command and argument to run next
- **Flag the pipeline position**: always show which phase we're in (Phase 1 / 2 / 3 / 4)

---

## Pipeline Overview

```
Phase 1: /issue-ticket    → GitHub issue with DoD
Phase 2: /prioritize      → ROI-ranked list of Todo issues
Phase 3: /implement-issue → feature branch + code + PR
Phase 4: /review-pr       → code review + GitHub verdict
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
/prioritize
```
Use `n=3` (or any number) to see the top N ready issues ranked by ROI.

> Skip Phase 2 if you already know what to implement next.
---

---

## Phase 2 — Prioritize → Pick the Next Issue

If the developer runs `/prioritize` and wants guidance on what to do next:

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

**Next: Request a code review.**

Run:
```
/review-pr
```
Then enter `{pr-number}` when asked for the PR number.

---

---

## Phase 4 — Review Complete

After `/review-pr` has been run and a verdict delivered:

---
**✅ Phase 4 complete.**

- If verdict is **Approve**: merge when ready.
- If verdict is **Request Changes**: address feedback, push commits, re-run `/review-pr`.
- If verdict is **Comment**: resolve open questions, then re-run `/review-pr`.
---
````
