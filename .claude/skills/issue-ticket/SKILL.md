````skill
---
name: issue-ticket
description: Create a new GitHub issue from an unstructured idea, or edit an existing issue to reflect requirement changes.
disable-model-invocation: true
argument-hint: [optional brief idea summary] repo=[repo-or-owner/repo]
---

# Issue Ticket → GitHub Issue

Create or edit well-structured GitHub issues with title, description, Definition of Done, and labels. Works against any target repo via `{TARGET_OWNER}/{TARGET_REPO}` context.

## Step 0 — Resolve Target Repo

Follow the standard three-step resolution:
1. If `repo=owner/repo` or `repo=shortname` was passed as an argument, use that.
2. If multiple repos are detectable in context (open files, workspace folders), ask: "Which repo — e.g. `utilityiou` or `agent-skills`?"
3. Otherwise, silently use `{TARGET_OWNER}/{TARGET_REPO}` from context.

Set `RESOLVED_OWNER` and `RESOLVED_REPO` for all subsequent steps.

---

## Step 1 — Determine Mode

**Step 0 — Resolve target repo.**

If `repo=` was provided at invocation, use it (shorthand `repo=agent-skills` → `{TARGET_OWNER}/agent-skills`; `owner/repo` overrides owner). If multiple repos are evident in workspace context and none is clearly indicated, ask: _"Which repo should this issue be created in? (default: `{TARGET_OWNER}/{TARGET_REPO}`)"_. Otherwise use `{TARGET_REPO}` silently.

**Step 1 — Determine mode.**
Ask: "Are you creating a **new** issue or **editing** an existing one?"

---

## Workflow: Creating a New Issue

**Step 2 — Listen first.**
Read everything the user shares before responding. Do not suggest code, solutions, or structure yet. Acknowledge you've heard the idea.

**Step 3 — Ask clarifying questions, one at a time.**
Gather what you need to write a clear issue:
- What problem does this solve? Who is affected?
- What is the expected user experience / workflow?
- Are there edge cases or constraints to consider?
- How does this interact with existing features?
- What is MVP scope vs. nice-to-have?

Wait for an answer before asking the next question. Stop when you have enough context.

**Step 4 — Propose the issue structure.**
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
  gh label list --repo {RESOLVED_OWNER}/{RESOLVED_REPO}
  ```

**Step 5 — Create the issue (optional).**
Once approved, ask if the user wants to create it now. If yes, capture the URL directly from the create command and add to the project board if one exists:

```bash
# Create issue and capture its URL
ISSUE_URL=$(gh issue create \
  --repo {RESOLVED_OWNER}/{RESOLVED_REPO} \
  --title "Issue title" \
  --body-file /tmp/issue-body.md \
  --label "label1,label2" \
  --json url --jq .url)

echo "Created: $ISSUE_URL"

# Discover project number and add to board if a project exists
PROJECT_NUMBER=$(gh project list --owner {RESOLVED_OWNER} --format json \
  --jq '.projects[0].number // empty' 2>/dev/null)

if [ -n "$PROJECT_NUMBER" ]; then
  gh project item-add "$PROJECT_NUMBER" --owner {RESOLVED_OWNER} --url "$ISSUE_URL"
  echo "Added to project board #$PROJECT_NUMBER"
fi
```

> **Note:** Write the issue body to `/tmp/issue-body.md` via a file creation step before running this block, to avoid shell quoting problems with multi-line bodies.

---

## Workflow: Editing an Existing Issue

**Step 2 — Identify the issue.**
Ask for the issue number. (Repo is already resolved from Step 0.)

**Step 3 — Fetch and display current issue.**
```bash
gh issue view {number} --repo {RESOLVED_OWNER}/{RESOLVED_REPO} --json title,body,labels
```

Display:
- Current title
- Current description
- Current labels

**Step 4 — Understand the change.**
Ask: "What would you like to change about this issue?"

Listen to their revision request. Ask clarifying questions one at a time as needed.

**Step 5 — Propose before/after comparison.**

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

**Step 6 — Update the issue (optional).**
Once approved:

```bash
gh issue edit {number} --repo {RESOLVED_OWNER}/{RESOLVED_REPO} \
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
