# agent-skills

Generalized AI agent skill definitions for GitHub Copilot and Claude Code — decoupled from any specific project repo.

## What This Is

A single source of truth for org-wide AI agent skills. Skills here work against **any** target GitHub repo, not just one project.

## Skills

| Skill | Purpose |
|---|---|
| `/issue-ticket` | Raw idea → structured GitHub issue (create or edit) |
| `/prioritize` | Rank Todo issues by ROI score |
| `/implement-issue` | GitHub issue → branch + code + PR |
| `/review-pr` | Code review against project standards + DoD |
| `/plan-issue` | Guided full pipeline: idea → issue → prioritize → implement → review |
| `/pr-triage` | Unified ROI-ranked PR action queue — open/awaiting-review (scope=team), changes-requested (scope=rework), or personal cross-repo inbox (scope=mine). Emits `suggested_next_tool` for autonomous pipeline agents. |

## Usage

### Option 1 — psis (CLI container, for non-developers)

One-time setup — add to `~/.zshrc`:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
alias psis='docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -e GITHUB_TOKEN=$(gh auth token) \
  ghcr.io/pacific-shore-innovations-llc/agent-skills:latest'
```

Invoke a skill:

```bash
psis --project utilityiou --skill prioritize n=3
psis --project utilityiou --skill issue-ticket
psis --project utilityiou --skill prioritize n=5 --branch feature/my-branch
```

### Option 2 — Multi-root VS Code Workspace (for developers)

Add this repo as a second root alongside your project repo in a `.code-workspace` file:

```json
{
  "folders": [
    { "path": "../your-project" },
    { "path": "../agent-skills" }
  ]
}
```

Skills in `.claude/skills/` are auto-discovered by GitHub Copilot and Claude Code.

Set your target in `.envrc` at the workspace or project level:

```bash
export TARGET_OWNER=Pacific-Shore-Innovations-LLC
export TARGET_REPO=utilityiou
```

## How Skills Are Parameterized

All skills use two runtime variables instead of hardcoded values:

| Variable | Description | Example |
|---|---|---|
| `TARGET_OWNER` | GitHub org or user | `Pacific-Shore-Innovations-LLC` |
| `TARGET_REPO` | Repository name | `utilityiou` |

When using **psis**, these are injected by the container entrypoint from the `--project` flag.

When using **VS Code**, these come from your `.envrc` or the project's CLAUDE.md context.

## Adding a New Skill

1. Create `.claude/skills/{skill-name}/SKILL.md`
2. Add YAML frontmatter with `name:`, `description:`, `disable-model-invocation: true`
3. Use `{TARGET_OWNER}` / `{TARGET_REPO}` instead of hardcoded values
4. Open a PR to this repo — all projects adopting `agent-skills` get the new skill immediately

## Repo Structure

```
.claude/skills/         — Skill definitions (one directory per skill)
docker/
  Dockerfile            — Container definition
  entrypoint.sh         — Context fetch + Claude CLI invocation
  psis                  — Wrapper script (copy to PATH)
scripts/
  create_github_labels.sh — Seed standard labels in a target repo
```

## Requirements

- **psis users**: Docker Desktop or Podman, Anthropic API key, `gh` CLI authenticated
- **VS Code users**: GitHub Copilot or Claude Code extension, `gh` CLI authenticated
