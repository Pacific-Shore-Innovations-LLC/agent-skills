````skill
---
name: issue-ticket
description: Create a new GitHub issue from an unstructured idea, or edit an existing issue to reflect requirement changes.
disable-model-invocation: true
argument-hint: [optional brief idea summary]
---

# Issue Ticket → GitHub Issue

Create or edit well-structured GitHub issues with title, description, Definition of Done, and labels. Works against any target repo via `{TARGET_OWNER}/{TARGET_REPO}` context.

## Initial Question

**Step 0 — Determine mode.**
Ask: "Are you creating a **new** issue or **editing** an existing one?"

---

## Workflow: Creating a New Issue

**Step 1 — Listen first.**
Read everything the user shares before responding. Do not suggest code, solutions, or structure yet. Acknowledge you've heard the idea.

**Step 2 — Ask clarifying questions, one at a time.**
Gather what you need to write a clear issue:
- What problem does this solve? Who is affected?
- What is the expected user experience / workflow?
- Are there edge cases or constraints to consider?
- How does this interact with existing features?
- What is MVP scope vs. nice-to-have?

Wait for an answer before asking the next question. Stop when you have enough context.

**Step 3 — Propose the issue structure.**
Present the following for user approval, following the **Standard Issue Format** (see reference section below):

- **Title**: Clear and concise (a single GitHub issue title)
- **Description** with sections:
  - *Problem Statement* — why this matters
  - *Proposed Solution* — what we'd build
  - *User Impact* — who benefits and how
  - *Technical Scope* — what's included and what's NOT
  - *Dependencies* — links to blocking issues (if any)
  - *Definition of Done* — specific, testable checklist items
- **Labels** — fetch available labels from the target repo:
  ```bash
  gh label list --repo {TARGET_OWNER}/{TARGET_REPO}
  ```

**Step 4 — Create the issue (optional).**
Once approved, ask if the user wants to create it now. If yes:

```bash
gh issue create \
  --repo {TARGET_OWNER}/{TARGET_REPO} \
  --title "Issue title" \
  --body "Description here" \
  --label "label1,label2"
```

If the target repo has a GitHub Project board, add the issue to it:
```bash
ISSUE_URL=$(gh issue view {number} --repo {TARGET_OWNER}/{TARGET_REPO} --json url --jq .url)
gh project item-add {PROJECT_NUMBER} --owner {TARGET_OWNER} --url "$ISSUE_URL"
```

---

## Workflow: Editing an Existing Issue

**Step 1 — Identify the issue.**
Ask for the issue number.

If `TARGET_REPO` is not already in context, ask:
"Which repository? (Press **Enter** for `{TARGET_OWNER}/{TARGET_REPO}`, or type `owner/repo`)"

**Step 2 — Fetch and display current issue.**
```bash
gh issue view {number} --repo {TARGET_OWNER}/{TARGET_REPO} --json title,body,labels
```

Display:
- Current title
- Current description
- Current labels

**Step 3 — Understand the change.**
Ask: "What would you like to change about this issue?"

Listen to their revision request. Ask clarifying questions one at a time as needed.

**Step 4 — Propose before/after comparison.**

**BEFORE:**
```
Title: [old title]
Description: [old description]
Labels: [old labels]
```

**AFTER:**
```
Title: [new title]
Description: [new description]
Labels: [new labels]
```

**Step 5 — Update the issue (optional).**
Once approved:

```bash
gh issue edit {number} --repo {TARGET_OWNER}/{TARGET_REPO} \
  --title "New title" \
  --body "New description" \
  --add-label "new-label" \
  --remove-label "old-label"
```

---

## Standard Issue Format

All GitHub issues must follow this structure:

**Problem Statement:**
Clear description of the problem or need this issue addresses.

**Proposed Solution:**
How the feature/fix will work, including key implementation points.

**User Impact:**
How this affects end users and what value it delivers.

**Technical Scope:**
What's included and explicitly what's NOT included in this issue.

**Dependencies:**
Links to other issues that must be completed first (if any). Use `#issue-number` format.

**Definition of Done:**
Detailed checklist of specific, testable criteria. Adapt categories to the project's tech stack. Common categories:

- [ ] Data model / schema changes
- [ ] Backend logic / API endpoints
- [ ] Frontend UI
- [ ] Tests (unit, integration, e2e)
- [ ] Documentation

Note: Not all categories apply to every issue. Include only what's relevant.

---

## Available Labels

Fetch the target repo's labels at runtime:
```bash
gh label list --repo {TARGET_OWNER}/{TARGET_REPO} --json name --jq '.[].name'
```

Choose the most appropriate subset. Common labels used across PSIS projects:
`mvp` · `high-priority` · `feature` · `enhancement` · `frontend` · `backend` · `testing` · `documentation` · `performance` · `auth` · `payments` · `infrastructure` · `analytics` · `mobile` · `i18n` · `post-mvp` · `future` · `in-progress`

---

## Example

**Input:**
> I'm thinking we need some way for users to see a dashboard showing which items have pending actions.

**Expected output (after clarifying questions):**
- Title: `User dashboard with pending action indicators`
- Labels: `feature`, `frontend`
- DoD includes: dashboard component, real-time status updates, tests, responsive layout
````
