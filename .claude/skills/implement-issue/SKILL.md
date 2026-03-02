````skill
---
name: implement-issue
description: Implement a GitHub issue by creating a feature branch, writing code to satisfy the Definition of Done, and creating a PR for review.
disable-model-invocation: true
argument-hint: [issue number]
---

# Implement Issue → Code → PR

Take a GitHub issue from planning to implementation, tracking Definition of Done completion.

## Initial Questions

**Step 0 — Identify the issue and repo.**
Ask: "Which issue number are you implementing?"

If `TARGET_REPO` is not in context, ask: "Which repository? (Press **Enter** for `{TARGET_OWNER}/{TARGET_REPO}`, or type `owner/repo`)"

**Step 1 — Choose implementation mode.**
Ask: "Implementation mode: **Guided** (approve each step) or **Autonomous** (full auto-implementation)?"

- **Guided** (Default): Agent proposes each section, waits for approval before writing code
- **Autonomous**: Agent implements entire DoD automatically with minimal interruption

---

## Workflow: Guided Mode (Default)

**Step 2 — Fetch issue and create branch.**

Retrieve the issue:
```bash
gh issue view {number} --repo {TARGET_OWNER}/{TARGET_REPO} --json title,body,labels
```

Discover the default branch:
```bash
DEFAULT_BRANCH=$(gh api repos/{TARGET_OWNER}/{TARGET_REPO} --jq .default_branch)
```

Create feature branch:
```bash
git checkout "$DEFAULT_BRANCH"
git pull origin "$DEFAULT_BRANCH"
git checkout -b issue-{number}-{brief-description}
```

Display:
- Issue title
- Definition of Done checklist
- Identified DoD categories (schema, backend, frontend, testing, docs)

**Step 3 — Propose implementation plan.**
Show the order in which DoD items will be tackled. Typical order:
1. Data model / schema changes + migrations
2. Backend models and API layer
3. Business logic / service layer
4. Frontend UI components
5. Testing (unit, integration, e2e)
6. Documentation updates

Ask: "Does this implementation order work for you?"

**Step 4 — Implement each section with approval.**
For each DoD category:

1. **Show what will be implemented:**
   - List specific files to create/modify
   - Describe key implementation details
   - Reference the project's coding standards or constitution if available

2. **Wait for approval:**
   - User can approve, ask questions, or request modifications

3. **Write the code:**
   - Follow the project's constitution or standards document if present (check for `.speckit/constitution-core.md`, `docs/STANDARDS.md`, `CONTRIBUTING.md`, or similar)
   - Consult any spec docs referenced in the issue or found in the project's `docs/` directory
   - Create files, write tests, update docs

4. **Mark DoD items complete:**
   - Check off completed items from the DoD list
   - Commit: `feat: implement {description} (issue #{number})`

5. **Show progress:**
   - Display updated DoD checklist
   - Indicate what's next

**Step 5 — Verify completion and create PR.**
When all DoD items are complete:

1. Run the project's test suite. Check the project's `README.md`, `CLAUDE.md`, or `Makefile` for the correct test command. Common patterns:
   ```bash
   # Python projects
   pytest
   # or: docker compose exec app pytest

   # Node.js projects
   npm test
   # or: npm run typecheck && npm run lint

   # Generic
   make test
   ```

2. **Walk through the pre-PR quality gate** (`.claude/skills/implement-issue/pre-pr-checklist.md`):
   - Go through each checklist item interactively with the user
   - Mark each item ✅ pass or ❌ fail
   - **Block PR creation if any item is ❌** — fix the issue first, or explicitly defer with a linked follow-up issue noted in the PR body

3. Ask: "Ready to create PR?"

4. If yes:
   ```bash
   gh pr create \
     --repo {TARGET_OWNER}/{TARGET_REPO} \
     --title "Implement issue #${number}: ${title}" \
     --body "Closes #${number}\n\n## Changes\n\n${summary}\n\n## Definition of Done\n\n${DoD checklist with checked items}" \
     --assignee "@me"
   ```

---

## Workflow: Autonomous Mode

**Step 2 — Fetch issue and create branch.**
Same as Guided Mode.

**Step 3 — Show implementation plan.**
Display the full implementation plan with all DoD categories and file changes.

Ask: "Proceed with full autonomous implementation?"

**Step 4 — Execute all DoD items.**
Implement the entire issue following the plan:

1. Schema/data → Backend → Frontend → Testing → Docs
2. Follow the project's coding standards
3. Commit after each major section
4. Track DoD completion internally

**Step 5 — Show summary.**
When complete, display:
- All files created/modified
- All DoD items checked off
- Test results summary

**Walk through the pre-PR quality gate** (`.claude/skills/implement-issue/pre-pr-checklist.md`):
- Go through each checklist item interactively with the user
- Mark each item ✅ pass or ❌ fail
- **Block PR creation if any item is ❌** — fix the issue first, or explicitly defer with a linked follow-up issue

Ask: "Ready to create PR?"

If yes, create PR (same as Guided Mode).

---

## Key Implementation Guidelines

**Standards and patterns:**
1. Check for a **constitution** or standards document: `.speckit/constitution-core.md`, `docs/STANDARDS.md`, `CONTRIBUTING.md`, or equivalent
2. Check for **spec docs** in `docs/` or `docs/development/` referenced in the issue body
3. Follow naming conventions, error handling, and testing patterns established in the project

**Code quality:**
- Follow the project's naming conventions
- Write tests for all new functionality
- Add type annotations where the project uses them
- Handle errors gracefully
- Update documentation

**Commit messages:**
- Format: `feat: description (issue #123)` or `fix: description (issue #123)`
- One commit per logical section in Guided mode
- Multiple commits in Autonomous mode (schema, backend, frontend, tests)

---

## Example Usage

**Input:**
```
/implement-issue
35
Guided
```

**Expected workflow:**
1. Fetch issue #35 from `{TARGET_OWNER}/{TARGET_REPO}`
2. Discover default branch, create `issue-35-device-management`
3. Display DoD with applicable categories
4. Propose first section, wait for approval
5. Progress through all DoD items with commits
6. All DoD complete → offer PR creation
7. Create PR with "Closes #35" and full DoD checklist
````
