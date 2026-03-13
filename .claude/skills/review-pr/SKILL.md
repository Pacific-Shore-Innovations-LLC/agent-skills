````skill
---
name: review-pr
description: Review a GitHub pull request for standards compliance, code quality, security, test coverage, and Definition of Done completeness. Posts review to GitHub.
disable-model-invocation: true
argument-hint: [PR number]
---

# Review Pull Request

Perform a thorough code review against the project's standards, and linked issue requirements.

## Initial Setup

**Step 0 — Identify the PR and repo.**
Ask: "Which PR number would you like me to review?"

If `TARGET_REPO` is not in context, ask:
"Which repository? (Press **Enter** for `{TARGET_OWNER}/{TARGET_REPO}`, or type `owner/repo`)"

---

## Workflow

**Step 1 — Fetch PR details.**

```bash
gh pr view {number} --repo {TARGET_OWNER}/{TARGET_REPO} --json title,body,headRefName,baseRefName,author,labels,files
gh pr diff {number} --repo {TARGET_OWNER}/{TARGET_REPO}
```

Display:
- PR title and author
- Branch: `{head}` → `{base}`
- Linked issue (extracted from `Closes #N` or `Fixes #N` in PR body)
- Files changed (count and list)

**Step 2 — Fetch linked issue DoD (if present).**
If a linked issue is found in the PR body:

```bash
gh issue view {issue-number} --repo {TARGET_OWNER}/{TARGET_REPO} --json title,body
```

Extract the Definition of Done checklist to use as a review baseline.

**Step 3 — Fetch project standards and relevant specs.**

Check for the project's standards document (in order of preference):
1. `.speckit/constitution-core.md`
2. `docs/STANDARDS.md`
3. `CONTRIBUTING.md`
4. `docs/ARCHITECTURE.md`

Also check for spec documents relevant to the changed files (e.g. `docs/development/`, `docs/api/`, schema files).

**Step 4 — Perform the review.**
Load `.claude/skills/review-pr/review-checklist.md` and walk through each item interactively:
- Assess each item against the PR diff: ✅ pass, ❌ fail, or ⚠️ concern
- Record specific file + line references for any ❌ / ⚠️ findings
- **Do not proceed to Step 5 until all checklist categories are assessed**

Checklist categories to cover:

### 1. Standards Compliance
If a constitution or standards document was found, verify the PR follows it. Common universal checks:
- [ ] Business logic is in a service/domain layer, NOT in thin handlers/controllers
- [ ] Handlers/controllers are thin (parse request, delegate, format response)
- [ ] Public API response schemas do not expose internal data model fields directly
- [ ] Naming conventions are consistent with the rest of the codebase
- [ ] No raw SQL with string interpolation (SQL injection risk)
- [ ] No circular imports or unexpected coupling

### 2. Code Quality
- [ ] Type annotations/hints present where the project uses them
- [ ] No `any` or equivalent untyped escapes without justification
- [ ] Error handling is explicit and appropriate
- [ ] No magic numbers — constants or named values used
- [ ] No hardcoded secrets, credentials, or API keys
- [ ] No debug/print/console.log statements left in code
- [ ] Functions are focused and single-purpose
- [ ] Edge cases considered and handled

### 3. Security
- [ ] Authorization/ownership checks on every resource access
- [ ] Input validated before entering the system
- [ ] No internal error details exposed to external callers
- [ ] File uploads (if any): type and size validation present
- [ ] Sensitive data not logged

### 4. Test Coverage
- [ ] Unit tests present for all new business logic
- [ ] Integration tests present for all new API endpoints or data flows
- [ ] Frontend component tests present (if UI changed)
- [ ] Edge cases and error scenarios covered
- [ ] Tests are meaningful (not just smoke tests)

### 5. Definition of Done Completeness
Cross-reference each DoD item from the linked issue:
- For each DoD checklist item: is it addressed in this PR?
- Flag any DoD items that appear incomplete or missing
- Note any items that are clearly out of scope for this PR

**Step 5 — Compile review report.**

---
## PR Review: #{number} — {title}

### Summary
Brief overview of what the PR does and overall impression.

### Standards Compliance
List any violations found. If none: ✅ No violations found.

### Code Quality
List any issues found. If none: ✅ All checks passed.

### Security
List any concerns found. If none: ✅ No security issues found.

### Test Coverage
List any gaps found. If none: ✅ Coverage looks complete.

### Definition of Done
| DoD Item | Status |
|----------|--------|
| Item 1   | ✅ Complete |
| Item 2   | ⚠️ Partial — description |
| Item 3   | ❌ Missing |

### Inline Comments
Specific file/line observations:
- `path/to/file.py` line 42: description of issue
- `path/to/component.tsx` line 17: description of issue

### Verdict
**[APPROVE / REQUEST CHANGES / COMMENT]**

Reason: Clear statement of why this verdict was chosen.
---

**Step 6 — Offer to post review to GitHub.**
Ask: "Would you like me to post this review to GitHub?"

If yes, ask: "Post as **Approve**, **Request Changes**, or **Comment**?"
(Pre-select based on verdict, but allow override.)

```bash
gh pr review {number} --repo {TARGET_OWNER}/{TARGET_REPO} \
  --{approve|request-changes|comment} \
  --body "{review body}"
```

---

## Verdict Guidelines

**Approve** when:
- All standards patterns followed
- No security issues
- Test coverage complete
- All DoD items addressed
- Only minor style suggestions (not blocking)

**Request Changes** when:
- Any standards/architecture violation present
- Any security concern present
- DoD items missing or incomplete
- Tests missing for new functionality
- Significant code quality issues

**Comment** when:
- PR is a draft or WIP
- Questions need answering before verdict
- Changes are non-code (docs, config only)

---

## Example Usage

**Input:**
```
/review-pr
42
```

**Expected output:**
1. Fetch PR #42, display title and files changed
2. Detect `Closes #35` → fetch issue #35 DoD
3. Load project standards + relevant specs
4. Analyze diff across all 5 dimensions
5. Display full review report in chat
6. Ask: "Post to GitHub?" → post with chosen verdict
````
