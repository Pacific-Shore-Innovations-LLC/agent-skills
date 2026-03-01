#!/usr/bin/env bash
# entrypoint.sh — psis container entrypoint
# Fetches project context from GitHub REST API (no clone required) and invokes Claude CLI.

set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────────────
TARGET_OWNER="Pacific-Shore-Innovations-LLC"
TARGET_REPO=""
SKILL=""
BRANCH=""
SKILL_ARGS=()

# Skills that require a full local checkout — blocked in container mode
UNSUPPORTED_SKILLS=("implement-issue")

# ─── Arg parsing ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project)   TARGET_REPO="$2"; shift 2 ;;
        --skill)     SKILL="$2"; shift 2 ;;
        --branch)    BRANCH="$2"; shift 2 ;;
        --owner)     TARGET_OWNER="$2"; shift 2 ;;
        *)           SKILL_ARGS+=("$1"); shift ;;
    esac
done

# ─── Validate required args ───────────────────────────────────────────────────
if [[ -z "$TARGET_REPO" ]]; then
    echo "ERROR: --project is required (e.g. --project utilityiou)" >&2
    exit 1
fi

if [[ -z "$SKILL" ]]; then
    echo "ERROR: --skill is required (e.g. --skill prioritize)" >&2
    echo "Supported skills: issue-ticket, prioritize, review-pr, plan-issue" >&2
    exit 1
fi

# ─── Block unsupported skills ────────────────────────────────────────────────
for blocked in "${UNSUPPORTED_SKILLS[@]}"; do
    if [[ "$SKILL" == "$blocked" ]]; then
        echo "ERROR: The /$SKILL skill requires a full local checkout and cannot run" >&2
        echo "       inside the psis container." >&2
        echo "" >&2
        echo "       To use /$SKILL, open the project repo in VS Code with the" >&2
        echo "       agent-skills repo as a second workspace root." >&2
        exit 1
    fi
done

# ─── Pre-flight: Anthropic API key ────────────────────────────────────────────
if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "ERROR: ANTHROPIC_API_KEY is not set." >&2
    echo "       Add it to your shell config:" >&2
    echo "         export ANTHROPIC_API_KEY=sk-ant-..." >&2
    exit 1
fi

echo "Checking Anthropic API key..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    "https://api.anthropic.com/v1/models")

if [[ "$HTTP_STATUS" != "200" ]]; then
    echo "ERROR: Anthropic API key check failed (HTTP $HTTP_STATUS)." >&2
    echo "       Verify your ANTHROPIC_API_KEY is valid and has sufficient credits." >&2
    exit 1
fi
echo "✓ Anthropic API key valid"

# ─── Pre-flight: GitHub auth ──────────────────────────────────────────────────
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "ERROR: GITHUB_TOKEN is not set." >&2
    echo "       Pass it with: -e GITHUB_TOKEN=\$(gh auth token)" >&2
    exit 1
fi
export GH_TOKEN="$GITHUB_TOKEN"

# ─── Resolve default branch ──────────────────────────────────────────────────
if [[ -z "$BRANCH" ]]; then
    echo "Resolving default branch for $TARGET_OWNER/$TARGET_REPO..."
    BRANCH=$(curl -sf \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/$TARGET_OWNER/$TARGET_REPO" \
        | jq -r '.default_branch')

    if [[ -z "$BRANCH" || "$BRANCH" == "null" ]]; then
        echo "WARN: Could not resolve default branch; falling back to 'main'" >&2
        BRANCH="main"
    fi
fi
echo "✓ Target branch: $BRANCH"

# ─── Fetch project context files from GitHub REST API ────────────────────────
CONTEXT_DIR="/workspace/context"
mkdir -p "$CONTEXT_DIR"

fetch_file() {
    local path="$1"
    local dest="$2"
    local encoded_path
    encoded_path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$path'))")

    HTTP_CODE=$(curl -s -o "$dest" -w "%{http_code}" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.raw+json" \
        "https://api.github.com/repos/$TARGET_OWNER/$TARGET_REPO/contents/$encoded_path?ref=$BRANCH")

    if [[ "$HTTP_CODE" == "200" ]]; then
        echo "  ✓ $path"
    else
        echo "  - $path (not found, skipping)"
        rm -f "$dest"
    fi
}

echo "Fetching project context from $TARGET_OWNER/$TARGET_REPO @ $BRANCH..."
fetch_file "CLAUDE.md"                          "$CONTEXT_DIR/CLAUDE.md"
fetch_file ".github/copilot-instructions.md"   "$CONTEXT_DIR/copilot-instructions.md"
fetch_file ".envrc"                            "$CONTEXT_DIR/.envrc"
fetch_file ".speckit/constitution-core.md"     "$CONTEXT_DIR/constitution-core.md"
fetch_file "docs/STANDARDS.md"                 "$CONTEXT_DIR/STANDARDS.md"
fetch_file "CONTRIBUTING.md"                   "$CONTEXT_DIR/CONTRIBUTING.md"

# ─── Parse .envrc (literal export KEY=value lines only) ──────────────────────
ENVRC_FILE="$CONTEXT_DIR/.envrc"
if [[ -f "$ENVRC_FILE" ]]; then
    echo "Parsing .envrc (literal export KEY=value lines only)..."
    while IFS= read -r line; do
        # Match only simple: export KEY=value or KEY=value (no subshells, no expansion)
        if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=([^$\`\(\)]*)[[:space:]]*$ ]]; then
            key="${BASH_REMATCH[2]}"
            val="${BASH_REMATCH[3]}"
            # Strip surrounding quotes if present
            val="${val%\"}"
            val="${val#\"}"
            val="${val%\'}"
            val="${val#\'}"
            export "$key=$val"
            echo "  ✓ Loaded: $key"
        fi
    done < "$ENVRC_FILE"
fi

# ─── Export runtime context variables ────────────────────────────────────────
export TARGET_OWNER
export TARGET_REPO

# ─── Discover GitHub project board number ────────────────────────────────────
echo "Discovering project board for $TARGET_OWNER..."
PROJECT_NUMBER=$(gh project list --owner "$TARGET_OWNER" --format json \
    | jq -r --arg repo "$TARGET_REPO" \
      '.projects[] | select(.title | ascii_downcase | contains($repo | ascii_downcase)) | .number' \
    | head -1)

if [[ -z "$PROJECT_NUMBER" || "$PROJECT_NUMBER" == "null" ]]; then
    PROJECT_NUMBER=$(gh project list --owner "$TARGET_OWNER" --format json \
        | jq -r '.projects[0].number // empty')
    if [[ -n "$PROJECT_NUMBER" ]]; then
        echo "  WARN: No project matched '$TARGET_REPO' — using first project (#$PROJECT_NUMBER)" >&2
    else
        echo "  WARN: No project boards found for $TARGET_OWNER" >&2
        PROJECT_NUMBER=""
    fi
fi

[[ -n "$PROJECT_NUMBER" ]] && echo "✓ Project board: #$PROJECT_NUMBER"
export PROJECT_NUMBER

# ─── Build system context for Claude ─────────────────────────────────────────
SYSTEM_CONTEXT=""

for f in CLAUDE.md copilot-instructions.md constitution-core.md STANDARDS.md CONTRIBUTING.md; do
    if [[ -f "$CONTEXT_DIR/$f" ]]; then
        SYSTEM_CONTEXT+="
=== $f (from $TARGET_OWNER/$TARGET_REPO @ $BRANCH) ===
$(cat "$CONTEXT_DIR/$f")
"
    fi
done

# ─── Copy skills into workspace ───────────────────────────────────────────────
cp -r /skills "$CONTEXT_DIR/skills"

# ─── Invoke Claude CLI ───────────────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────────────────"
echo " psis  |  /$SKILL  |  $TARGET_OWNER/$TARGET_REPO"
echo "──────────────────────────────────────────────────"
echo ""

SKILL_CONTENT=$(cat "$CONTEXT_DIR/skills/$SKILL/SKILL.md" 2>/dev/null || true)

if [[ -z "$SKILL_CONTENT" ]]; then
    echo "ERROR: Skill '$SKILL' not found in /skills." >&2
    echo "       Available skills: $(ls /skills | tr '\n' ' ')" >&2
    exit 1
fi

# Substitute runtime variables in skill content
SKILL_CONTENT="${SKILL_CONTENT//\{TARGET_OWNER\}/$TARGET_OWNER}"
SKILL_CONTENT="${SKILL_CONTENT//\{TARGET_REPO\}/$TARGET_REPO}"
SKILL_CONTENT="${SKILL_CONTENT//\{PROJECT_NUMBER\}/$PROJECT_NUMBER}"

export ANTHROPIC_API_KEY

claude \
    --system "$SYSTEM_CONTEXT

You are operating in psis container mode against $TARGET_OWNER/$TARGET_REPO.
TARGET_OWNER=$TARGET_OWNER
TARGET_REPO=$TARGET_REPO
PROJECT_NUMBER=${PROJECT_NUMBER:-unknown}
DEFAULT_BRANCH=$BRANCH

Active skill:
$SKILL_CONTENT" \
    "${SKILL_ARGS[@]+"${SKILL_ARGS[@]}"}"
