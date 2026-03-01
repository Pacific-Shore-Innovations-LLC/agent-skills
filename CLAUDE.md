# CLAUDE.md — agent-skills

This is the **agent-skills** repo: a generalized, project-agnostic home for org-wide AI agent skill definitions.

## Purpose

Skills in `.claude/skills/` work against **any** target GitHub repo. They use `{TARGET_OWNER}` and `{TARGET_REPO}` as runtime variables rather than hardcoded project paths.

## Runtime Context Variables

All skills depend on two variables being present in the agent's context at invocation time:

| Variable | Source (psis) | Source (VS Code) |
|---|---|---|
| `TARGET_OWNER` | Injected by `entrypoint.sh` from `--project` flag | `.envrc` in workspace root |
| `TARGET_REPO` | Same | Same |
| `PROJECT_NUMBER` | Discovered via `gh project list` by entrypoint | Discovered at skill runtime |

## Skill Overview

| Skill | File | Purpose |
|---|---|---|
| `issue-ticket` | `.claude/skills/issue-ticket/SKILL.md` | Raw idea → structured GitHub issue |
| `prioritize` | `.claude/skills/prioritize/SKILL.md` | ROI-ranked backlog |
| `implement-issue` | `.claude/skills/implement-issue/SKILL.md` | Issue → branch → code → PR |
| `review-pr` | `.claude/skills/review-pr/SKILL.md` | PR review against standards + DoD |
| `plan-issue` | `.claude/skills/plan-issue/SKILL.md` | Full pipeline orchestrator |

## Container Invocation (psis)

The `docker/entrypoint.sh` script:
1. Resolves `TARGET_OWNER` and `TARGET_REPO` from `--project` argument
2. Discovers default branch (`default_branch` field from GitHub REST API)
3. Fetches CLAUDE.md, `.envrc`, and constitution from the target repo via GitHub REST API (no clone needed)
4. Parses `.envrc` for literal `export KEY=value` lines only (no script execution)
5. Discovers project board number via `gh project list`
6. Injects all context into the Claude CLI session
7. Invokes: `claude --skill {skill-name} [args]`

## Multi-root VS Code Workspace Usage

Add this repo alongside your project repo in a `.code-workspace` file to make all skills available via slash commands. See `README.md` for setup.

## Adding Skills

1. Create `.claude/skills/{name}/SKILL.md`
2. Use `{TARGET_OWNER}` / `{TARGET_REPO}` — never hardcode
3. Set `disable-model-invocation: true` in frontmatter
4. PR to this repo

## What Not to Add Here

- Project-specific business logic (e.g. utilityiou rate calculation rules)
- Hardcoded credentials, paths, or org names
- Project-specific label sets (skills reference the target repo's labels at runtime)
