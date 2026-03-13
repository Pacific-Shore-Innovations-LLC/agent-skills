# PR Review Quality Gate Checklist

Walk through each item interactively during a PR review. Mark ✅ pass, ❌ fail, or ⚠️ concern. **All ❌ items require "Request Changes". ⚠️ items are at reviewer discretion.**

---

## 1. Architecture & Standards
*Reference: project standards document (`.speckit/constitution-core.md`, `docs/STANDARDS.md`, or `CONTRIBUTING.md`)*

- [ ] Business logic lives in the service/domain layer, not in route handlers or controllers
- [ ] Handlers/controllers are thin: parse request → call service → format response
- [ ] API response schemas do not expose internal data model fields directly
- [ ] Naming conventions consistent with the rest of the codebase
- [ ] No circular imports or unexpected coupling
- [ ] Error types used correctly per project convention
- [ ] No raw SQL with string interpolation

---

## 2. Code Quality

- [ ] No untyped escapes (`# type: ignore`, `any`, etc.) without justification
- [ ] No magic numbers — constants are named
- [ ] No debug statements (`print()`, `console.log()`, `pdb.set_trace()`, etc.)
- [ ] No commented-out code blocks
- [ ] Type hints/annotations present on all new functions/methods and exports where the project uses them
- [ ] Error handling covers expected failure paths (missing resources, validation, external APIs)
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Async/await used correctly where applicable — no blocking calls in async context

---

## 3. Security
*Reference: project security documentation if present (e.g. `docs/SECURITY.md`, `docs/development/SECURITY.md`)*

- [ ] Authorization/ownership checks present on every resource access
- [ ] All inputs validated before entering the system
- [ ] Internal error details not exposed to external callers (no stack traces in responses)
- [ ] Auth checks present on all non-public endpoints
- [ ] No new dependencies with known CVEs introduced

---

## 4. Test Coverage
*Reference: project testing documentation or `.speckit/constitution-reference.md` if present*

- [ ] Unit tests written for all new service/domain logic
- [ ] Integration tests written for all new API endpoints or data flows
- [ ] Edge cases covered (empty input, boundary values, error paths)
- [ ] Frontend type check and lint passes (if project has a frontend and changes were made)
- [ ] No existing tests broken

---

## 5. Definition of Done Completeness

- [ ] Linked issue identified (`Closes #N` or `Fixes #N` in PR body)
- [ ] Every DoD item from the linked issue is addressed in the diff
- [ ] No DoD item silently skipped — any deferral noted in PR body with follow-up issue linked
- [ ] Migration or schema change files included if data model changed
- [ ] Environment variable changes documented if new variables introduced

---

## Gate Result

Tally your assessments and select a verdict:

| Verdict | Condition |
|---|---|
| **Approve** | All items ✅ or ⚠️ with no blocking concerns |
| **Request Changes** | Any item ❌ |
| **Comment** | No blocking issues, but non-trivial feedback that warrants author acknowledgment |

Record specific ❌ / ⚠️ items with file + line references before rendering the final verdict.
