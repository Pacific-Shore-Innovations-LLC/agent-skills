# Agent Skills Constitution (Core Rules)

**Document Purpose**: Authoritative rules for authoring, modifying, and reviewing skills in this repo. All agents and human contributors must follow these rules. When a rule here contradicts guidance elsewhere, this document wins.

**Last Updated**: March 1, 2026
**Scope**: All skills in `.claude/skills/`, all contributions to this repo, all agents invoking these skills.

---

## I. SKILL FILE STRUCTURE

### A. Required Sections (in order)

Every `SKILL.md` MUST contain all of the following sections in this order:

1. **YAML frontmatter** (see Section I.B)
2. **Title** — `# SkillName → Output` format
3. **Invocation Signal** — orchestrator skills only (see Section V.C)
4. **`## Communication Style`** — terse behavioral directives (see Section IV)
5. **`## Workflow`** — numbered steps starting at Step 0 (repo resolution)
6. **`## Output Format`** — exact output template with rules
7. **`## Guardrails`** — explicit constraints (see Section VIII)
8. **`## Example`** — one complete input/output pair

Omitting any section is a constitution violation. Reordering sections is a constitution violation.

### B. Frontmatter Schema (NON-NEGOTIABLE)

```yaml
---
name: skill-name                    # kebab-case; MUST match the directory name exactly
description: One-sentence summary.  # Starts with a verb; one sentence only
disable-model-invocation: true      # ALWAYS — never omit or set false
argument-hint: [args] repo=[repo-or-owner/repo]  # ALL arguments; repo= is mandatory for every skill
---
```

Rules:
- `name` must be identical to the `.claude/skills/{name}/` directory name
- `description` starts with a verb (e.g. "Query", "Create", "Review", "Find")
- `disable-model-invocation: true` is non-negotiable — skills are invoked explicitly by the user, never auto-triggered
- `argument-hint` must always include `repo=[repo-or-owner/repo]` as an optional argument, even for skills that rarely need it

### C. Step 0 Is Always Repo Resolution

Every skill's `## Workflow` begins with **Step 0 — Resolve target repo**, using the exact three-step resolution order defined in Section II.B. No skill may skip Step 0 or reorder it.

---

## II. RUNTIME VARIABLES & REPO RESOLUTION

### A. Runtime Variables

| Variable | Source (psis) | Source (VS Code) | Description |
|---|---|---|---|
| `TARGET_OWNER` | `--project` flag via entrypoint | `.envrc` | GitHub org or user |
| `TARGET_REPO` | Same | Same | Repository name |
| `PROJECT_NUMBER` | `gh project list` at startup | Discovered at skill runtime | GitHub Projects v2 board number |

**NEVER hardcode**: owner names, repo names, project board IDs, or file paths specific to one project. Always use `{TARGET_OWNER}` and `{TARGET_REPO}` as placeholders.

### B. Repo Resolution — Step 0 (CANONICAL)

All skills implement Step 0 with this exact three-step resolution order:

1. **`repo=` provided at invocation** → use it
   - Shorthand `repo=agent-skills` → `{TARGET_OWNER}/agent-skills`
   - Full form `repo=some-org/other-repo` → overrides both owner and repo
2. **Multiple repos evident in workspace context and none clearly indicated by the request** → ask: _"Which repo? (default: `{TARGET_OWNER}/{TARGET_REPO}`)"_
3. **Otherwise** → use `{TARGET_REPO}` silently, no question asked

The resolved owner/repo pair is used for all subsequent `gh` CLI calls in that skill invocation.

### C. Discovering Project Board Number

When a skill needs the GitHub Projects v2 board number:

```bash
gh project list --owner {TARGET_OWNER} --format json
```

Select the project whose title most closely matches `{TARGET_REPO}`. If no match, use the first project. Record as `{PROJECT_NUMBER}`.

---

## III. OUTPUT FORMAT RULES

### A. Ranking Skills (prioritize-issues, prioritize-open-prs)

**Ranked list format** (non-negotiable):

```
TOP [N] {NOUN} — {TARGET_REPO}

#1. {Item Title} (#{id})
    [Secondary identifier if applicable]
    ROI: {score} | Value: {V}  Risk: {R}  Deps: {D}
    Why: {one sentence — no elaboration}

#2. ...

─────────────────────────────────────
NEXT STEPS:
✅ /skill-name → {id}   ← start here
✅ /skill-name → {id}   ← next
❌ Defer: {Title} (#{id}) — {one-phrase reason}
─────────────────────────────────────
```

Rules:
- NEXT STEPS block is **always the final section**, never omitted
- One-sentence rationale per item — one sentence, no sub-bullets, no elaboration
- ✅ = ready to act on; ❌ Defer = has unresolved blocker (state reason in one phrase)
- If fewer than N items available: `Note: only {k} items found — showing all {k}.`

### B. ROI Formula (canonical)

```
ROI Score = Value / (Risk + Dependencies)
```

Round to one decimal place. Higher is better. All three dimensions on a 1–10 scale.

**Business Value (1–10)**: P1/blocker = 10; P2/revenue-facing = 8–9; P3/internal = 5–7; P4/polish = 2–4. Label boosts +1–2 (capped at 10) for: `mvp`, `high-priority`, `critical`, `security`, `hotfix`.

**Risk (1–10)**: Architecture spike = 10; multi-service/migration = 8–9; complex-but-known = 5–7; small/isolated = 2–4.

**Dependencies (1–10)**: Blocked by external = 10; linked unresolved items = 7–9; some sequencing = 4–6; self-contained = 1–3.

### C. Action Skills (implement-issue, review-pr, plan-issue)

Phase / step transitions follow this pattern:

```
---
**✅ Phase N complete.** {One-sentence summary of what was done.}

**Next:** {Directive statement — what to do now.}

Run:
```
/skill-name [argument]
```

> {Optional: one-sentence note about mode or skip condition.}
---
```

Rules:
- No prose filler before or after the handoff block
- Always show the exact slash command with argument
- For plan-issue: always state the current phase number (Phase 1 / 2 / 3 / 4 / 5)

---

## IV. COMMUNICATION STYLE

### A. Mandatory Section

Every `SKILL.md` MUST contain a `## Communication Style` section with 3–6 behavioral directives specific to that skill's purpose.

### B. Global Rules (apply to all skills)

- **No preamble**: never open with "Here's what I found", "Great question", or any variant
- **No filler**: skip "Now that you've...", "Great job!", "Let me now..."
- **Lead with output**: show the result/ranked list/phase handoff first, then stop
- **Terse transitions**: phase handoffs are short, directive, and copy-paste-ready
- **Numbers first**: in ranked outputs, ROI score and dimensions appear on the same line as the title

### C. Per-Skill Tone Directives

| Skill | Tone |
|---|---|
| `issue-ticket` | Patient, exploratory; asks one clarifying question at a time; listens before proposing |
| `prioritize-issues` | Analytical, numbers-first; leads with ranked list, not explanatory prose |
| `prioritize-open-prs` | Same as prioritize-issues; PR number is the primary identifier |
| `implement-issue` | Terse, action-oriented; speaks in file paths, checklist items, and commit messages |
| `review-pr` | Objective, evidence-based; cites specific file/line and the specific constitution rule violated |
| `plan-issue` | Directive, pipeline-position-aware; shows exact next command; one phase at a time |

Tone must be consistent within a skill across all its output sections.

---

## V. SKILL INVOCATION RULES

### A. disable-model-invocation: true — non-negotiable

Skills are invoked explicitly by the user. Never set `disable-model-invocation: false`. Never omit this frontmatter key.

### B. SKILL.md as Active Workflow

When a skill is invoked by name (user types `/skill-name`, references it explicitly, or the SKILL.md is attached alongside a request), **the skill's workflow is the active workflow** — not background documentation to consult. The agent must follow it from Step 0 to completion.

If invocation intent is genuinely ambiguous, ask once before proceeding. Do not infer that an attached SKILL.md means "read this for reference."

### C. Invocation Signal (orchestrator skills only)

Skills that orchestrate other skills (currently: `plan-issue`) MUST include an `## Invocation Signal` section immediately after the title and before `## Communication Style`. It must:
- State explicitly that if this skill was invoked, start from Phase 1
- State what to do if invocation vs. direct implementation is ambiguous (ask once)

Non-orchestrator skills do not need this section.

### D. No Auto-Chaining

Skills MUST NOT auto-invoke or auto-chain to other skills. They guide the user to the next command via the NEXT STEPS block or phase handoff. The user controls when each skill runs.

---

## VI. CROSS-TOOL COMPATIBILITY

This section documents what is reliable across tools and what varies. Skill authors must write skills that work correctly in all three environments.

### A. What Is Reliable Across All Three (GHCP, Claude Code, psis)

- Skill discovery from `.claude/skills/{name}/SKILL.md`
- `disable-model-invocation: true` frontmatter is honored
- `name` frontmatter value is used as the slash command identifier
- `argument-hint` is displayed in the skill picker UI
- `gh` CLI commands execute in the workspace terminal (or psis container shell)
- Markdown headings (`##`) reliably delineate sections the agent uses to navigate

### B. GitHub Copilot (GHCP) — Specific Behavior

- **Auto-loads**: `.github/copilot-instructions.md` as system context
- **Does NOT auto-load**: `CLAUDE.md` or `.speckit/constitution-core.md`
- **Context loading**: workspace files are loaded on demand or via attachment; the agent may not have the full file tree in context by default
- **Multi-step skill state**: Copilot may not maintain step-by-step state as reliably as Claude Code across a long workflow — skill workflows should be designed so each step can be re-entered if context is lost

### C. Claude Code — Specific Behavior

- **Auto-loads**: `CLAUDE.md` as primary project context
- **Does NOT auto-load**: `.github/copilot-instructions.md`
- **Constitution**: `.speckit/constitution-core.md` must be explicitly referenced in `CLAUDE.md` to be loaded
- **Multi-step skill state**: generally more reliable at maintaining step state across a long skill execution; better at following inline workflow instructions to completion

### D. psis Container — Specific Behavior

- Injects `CLAUDE.md`, `.envrc`, and constitution from the target repo via GitHub REST API (no clone)
- Discovers `TARGET_OWNER`/`TARGET_REPO` from `--project` flag
- Discovers `PROJECT_NUMBER` via `gh project list` at container startup
- Does NOT have filesystem access to the target repo by default — skills must use `gh` CLI for all repo operations

### E. Implication for Skill Authors (CRITICAL)

**Every mandatory rule — Step 0, output format, guardrails — must be self-contained within the SKILL.md itself.** Do not rely on the agent having read `CLAUDE.md`, `copilot-instructions.md`, or this constitution at runtime. Those documents are for human contributors and session-level context. The SKILL.md is the authoritative runtime document.

Cross-reference constitution sections in SKILL.md comments if helpful for future editors, but never assume the agent read them.

---

## VII. CONTRIBUTING — GIT WORKFLOW

These rules apply to **all contributors** — human or agent — making changes to this repo.

### A. Branch Rules (NON-NEGOTIABLE)

- **NEVER commit directly to `main`**
- Every change starts with a GitHub issue
- Branch naming: `issue-{number}-{brief-description}` (e.g. `issue-9-speckit-constitution`)
- One branch per issue; one PR per issue

### B. Workflow

```bash
# Start from current main
git checkout main && git pull origin main

# Create feature branch
git checkout -b issue-{number}-{brief-description}

# Make changes, then commit
git add -A
git commit -m "{type}: {short description}

{optional body}

Closes #{number}"

# Push and open PR
git push -u origin issue-{number}-{brief-description}
gh pr create --base main --title "..." --body-file /tmp/pr.md
```

### C. Conventional Commit Types

| Type | When to use |
|---|---|
| `feat:` | New skill or new capability |
| `fix:` | Correcting a bug in skill logic |
| `docs:` | Documentation-only changes (CLAUDE.md, README, constitution) |
| `refactor:` | Restructuring without behavior change |
| `chore:` | Tooling, CI, repo infrastructure |

### D. PR Dependencies

If a branch is based on another unmerged branch (not `main`), the PR body must state:
> **Note:** This branch depends on PR #{n}. Merge that PR first, then rebase this branch onto `main` before merging.

### E. PR Body Minimum Content

- One-paragraph summary of what changed and why
- Bulleted list of specific changes
- `Closes #{number}` at the end

---

## VIII. GUARDRAILS CONVENTION

### A. Every Skill MUST Have a `## Guardrails` Section

Silence is not a guardrail. If a skill has a constraint on its behavior, it must be stated explicitly in the Guardrails section.

### B. Required Guardrails — Read-Only / Analytical Skills

Skills that only read and rank (currently: `prioritize-issues`, `prioritize-open-prs`):

- **NEVER** create issues, branches, or pull requests
- **NEVER** recommend items not in the correct state (non-Todo issues, closed/merged PRs)
- **NEVER** recommend items with unresolved blockers as ✅ (mark ❌ Defer instead)
- **ALWAYS** include a NEXT STEPS block, even if all items are deferred

### C. Required Guardrails — Action Skills

Skills that make changes (currently: `implement-issue`):

- **NEVER** commit directly to `main`
- **NEVER** skip the DoD checklist before creating a PR
- **ALWAYS** create a feature branch before making any file changes
- **ALWAYS** verify the issue is in an appropriate state (open, assigned or unassigned) before starting implementation

### D. Required Guardrails — Review Skills

Skills that post reviews (currently: `review-pr`):

- **NEVER** approve a PR with unresolved constitution violations
- **NEVER** post a review without completing all review dimensions
- **ALWAYS** cite the specific constitution section or file/line for each finding

### E. Proposing New Guardrails

If a skill should have a constraint not covered above, add it to the skill's Guardrails section and open a follow-up issue to add it to this document. Ad-hoc guardrails in one skill that should apply broadly are a signal that the constitution needs updating.
