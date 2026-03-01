#!/usr/bin/env bash
# create_github_labels.sh — Seed standard labels in a target GitHub repo
#
# Usage:
#   ./scripts/create_github_labels.sh owner/repo
#   ./scripts/create_github_labels.sh Pacific-Shore-Innovations-LLC/agent-skills

set -euo pipefail

REPO="${1:-}"

if [[ -z "$REPO" ]]; then
    echo "Usage: $0 owner/repo" >&2
    exit 1
fi

create_label() {
    local name="$1"
    local color="$2"
    local description="$3"

    if gh label create "$name" \
        --repo "$REPO" \
        --color "$color" \
        --description "$description" \
        --force 2>/dev/null; then
        echo "  ✓ $name"
    else
        echo "  - $name (skipped)"
    fi
}

echo "Creating labels in $REPO..."

# Priority / status
create_label "mvp"           "e11d48" "Must have for MVP launch"
create_label "high-priority" "dc2626" "Urgent, blocking work"
create_label "in-progress"   "f59e0b" "Currently being worked on"

# Type
create_label "feature"       "0284c7" "New feature"
create_label "enhancement"   "0ea5e9" "Improvement to existing feature"
create_label "bug"           "dc2626" "Something is broken"

# Domain
create_label "frontend"      "7c3aed" "Frontend changes"
create_label "backend"       "16a34a" "Backend/API changes"
create_label "infrastructure" "64748b" "Deployment/DevOps"

# Quality
create_label "testing"       "0891b2" "Test-related work"
create_label "documentation" "6366f1" "Documentation updates"
create_label "performance"   "d97706" "Performance optimization"

# Specialized
create_label "auth"          "b45309" "Authentication/authorization"
create_label "payments"      "059669" "Payment integration"
create_label "analytics"     "0369a1" "Analytics and reporting"
create_label "mobile"        "7c3aed" "Mobile-specific work"
create_label "i18n"          "6b7280" "Internationalization"
create_label "security"      "dc2626" "Security fix or hardening"

# Timeline
create_label "post-mvp"      "94a3b8" "After initial launch"
create_label "future"        "cbd5e1" "Future consideration"

echo ""
echo "Done. Labels created in $REPO."
