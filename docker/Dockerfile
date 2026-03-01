FROM alpine:3.19

LABEL org.opencontainers.image.title="psis"
LABEL org.opencontainers.image.description="Pacific Shore Innovation Skills — AI agent skill runner"
LABEL org.opencontainers.image.source="https://github.com/Pacific-Shore-Innovations-LLC/agent-skills"

# System dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    nodejs \
    npm \
    python3

# GitHub CLI
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community github-cli

# Claude Code CLI (Anthropic)
RUN npm install -g @anthropic-ai/claude-code

# Skills live at /skills inside the image
COPY .claude/skills /skills

# Container scripts
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
