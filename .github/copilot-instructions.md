# GitHub Copilot Instructions — agent-skills

This repo contains generalized AI agent skill definitions for use with GitHub Copilot, Claude Code, and the `psis` CLI container.

## What This Repo Is

A single source of truth for org-wide agent skills. Skills work against **any** target GitHub repo using runtime variables (`TARGET_OWNER`, `TARGET_REPO`) rather than hardcoded paths.

## Skills

| Skill | Purpose |
|---|---|
| `/issue-ticket` | Raw idea → structured GitHub issue (create or edit) |
| `/prioritize` | ROI-ranked backlog from GitHub project board |
| `/implement-issue` | GitHub issue → feature branch + code + PR |
| `/review-pr` | Code review against project standards + DoD |
| `/plan-issue` | Full pipeline: idea → issue → prioritize → implement → review |

## Key Rules for Skill Authoring

- **Never hardcode** `owner`, `repo`, project board IDs, or file paths specific to one project
- **Always use** `{TARGET_OWNER}` and `{TARGET_REPO}` as runtime variable placeholders
- **Set** `disable-model-invocation: true` in YAML frontmatter — skills are invoked explicitly
- **Discover** the project board number at runtime via `gh project list --owner {TARGET_OWNER}`
- **Discover** the default branch via `gh api repos/{TARGET_OWNER}/{TARGET_REPO} --jq .default_branch`

## Skill Invocation Rule

When a user explicitly invokes a skill by name (e.g. `/plan-issue`, `/implement-issue`, `/review-pr`), **always follow the workflow defined in that skill's SKILL.md from the beginning** — even if the SKILL.md is also present as a file attachment in context, and even if the underlying task seems directly actionable without following the pipeline. A SKILL.md attached as context is the active workflow to execute, not background documentation to consult. If invocation intent is ambiguous, ask before skipping steps.

## Runtime Variables

These are injected by the container entrypoint (psis) or set in `.envrc` for VS Code usage:

```
TARGET_OWNER   — GitHub organization or user (e.g. Pacific-Shore-Innovations-LLC)
TARGET_REPO    — Repository name (e.g. utilityiou)
```

## Skills Directory Structure

```
.claude/skills/
├── issue-ticket/SKILL.md
├── prioritize-issues/SKILL.md
├── prioritize-open-prs/SKILL.md
├── implement-issue/SKILL.md
├── review-pr/SKILL.md
└── plan-issue/SKILL.md
```

## Questions

When implementation details are unclear, check `CLAUDE.md` first. Ask for clarification if needed.
