# Pre-PR Quality Gate Checklist

Walk through each item interactively before creating a PR. Mark ✅ pass or ❌ fail. **All items must pass before proceeding.**

---

## 1. Architecture & Standards
*Reference: project standards document (`.speckit/constitution-core.md`, `docs/STANDARDS.md`, or `CONTRIBUTING.md`)*

- [ ] Business logic lives in the service/domain layer, not in route handlers or controllers
- [ ] Handlers/controllers are thin: parse request → call service → format response
- [ ] API response schemas do not expose internal data model fields directly
- [ ] Naming conventions followed per project standards
- [ ] No circular imports or unexpected coupling
- [ ] Error types used correctly per project convention (e.g. client errors vs. business logic errors)
- [ ] No raw SQL with string interpolation

---

## 2. Code Quality

- [ ] No untyped escapes (`# type: ignore`, `any`, etc.) without justification
- [ ] No magic numbers — constants defined and named
- [ ] No debug statements (`print()`, `console.log()`, `pdb.set_trace()`, etc.)
- [ ] No commented-out code blocks left in
- [ ] All new functions/methods have type hints or type annotations where the project uses them
- [ ] Error handling covers expected failure cases (missing resources, validation errors, external API failures)
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Async/await used correctly where applicable — no blocking calls in async context

---

## 3. Tests
*Reference: project testing documentation or `.speckit/constitution-reference.md` if present*

- [ ] Unit tests written for all new service/domain logic
- [ ] Integration tests written for all new API endpoints or data flows
- [ ] Edge cases covered (empty input, boundary values, error paths)
- [ ] Project test suite passes — check `README.md`, `CLAUDE.md`, or `Makefile` for the correct command
- [ ] Frontend type check and lint passes (if project has a frontend and changes were made)

---

## 4. Definition of Done Completeness

- [ ] Every DoD item from the linked issue is checked off
- [ ] No DoD item was skipped or deferred without explicit note in PR body
- [ ] Migration or schema change files included if data model changed
- [ ] Environment variable changes documented (e.g. `.env.example` updated if needed)

---

## 5. Documentation & Housekeeping

- [ ] Inline docstrings on new public functions/classes (or JSDoc on exported components)
- [ ] No stray TODO comments added without a linked issue
- [ ] Project contributor documentation updated if new patterns or conventions were introduced
- [ ] Relevant spec docs updated if implementation diverged from spec (note divergence in PR body)

---

## Gate Result

If any item is ❌:
- Fix the issue before creating the PR, **or**
- Explicitly acknowledge the gap in the PR body with a linked follow-up issue

**Do not create the PR until all items are ✅ or explicitly deferred.**
