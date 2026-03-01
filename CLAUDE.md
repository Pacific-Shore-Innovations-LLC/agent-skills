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
| `prioritize-issues` | `.claude/skills/prioritize-issues/SKILL.md` | ROI-ranked Todo backlog |
| `prioritize-open-prs` | `.claude/skills/prioritize-open-prs/SKILL.md` | ROI-ranked open PR review queue |
| `implement-issue` | `.claude/skills/implement-issue/SKILL.md` | Issue → branch → code → PR |
| `review-pr` | `.claude/skills/review-pr/SKILL.md` | PR review against standards + DoD |
| `plan-issue` | `.claude/skills/plan-issue/SKILL.md` | Full pipeline orchestrator |
| `pr-triage` | `.claude/skills/pr-triage/SKILL.md` | ROI-ranked PR action queue (scope=mine/team/rework) |

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

## Repo Resolution Convention

All skills support an optional `repo=` argument at invocation time:

- `repo=agent-skills` — shorthand; owner resolves to `TARGET_OWNER`
- `repo=some-org/other-repo` — explicit `owner/repo` for cross-org targets

**Resolution order (applied as Step 0 in every skill):**
1. If `repo=` was provided at invocation → use it
2. If workspace context contains multiple repos and none is clearly indicated by the request → ask: _"Which repo? (default: `{TARGET_OWNER}/{TARGET_REPO}`)"_
3. Otherwise → use `TARGET_REPO` silently, no question asked

Every skill's frontmatter `argument-hint` must include `repo=[repo]` as an optional argument.

## Adding Skills

1. Create `.claude/skills/{name}/SKILL.md`
2. Use `{TARGET_OWNER}` / `{TARGET_REPO}` — never hardcode
3. Set `disable-model-invocation: true` in frontmatter
4. PR to this repo

## Contributing — Git Workflow

When making any changes to this repo (new skill, renamed skill, doc updates), always follow this branching pattern — **never commit directly to `main`**:

```bash
# Start from a current main
git checkout main && git pull origin main

# Create a feature branch named after the issue
git checkout -b issue-{number}-{brief-description}

# Make changes, then commit
git add -A
git commit -m "feat|fix|docs: short description\n\nCloses #{number}"

# Push and open a PR
git push -u origin issue-{number}-{brief-description}
gh pr create --base main --title "..." --body-file /tmp/pr.md
```

Branch naming: `issue-{number}-{brief-description}` (e.g. `issue-5-prioritize-open-prs-and-rename`)

This applies even when the agent itself is executing implementation work against this repo as the target.

## What Not to Add Here

- Project-specific business logic (e.g. utilityiou rate calculation rules)
- Hardcoded credentials, paths, or org names
- Project-specific label sets (skills reference the target repo's labels at runtime)
