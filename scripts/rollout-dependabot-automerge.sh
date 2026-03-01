#!/usr/bin/env bash
# Rollout Dependabot Auto-Merge workflow to all zircote repositories
#
# Usage:
#   ./scripts/rollout-dependabot-automerge.sh [--dry-run] [--repo REPO]
#
# Options:
#   --dry-run    Show what would be done without making changes
#   --repo REPO  Only process a single repository (for testing)
#
# Requirements:
#   - gh CLI authenticated with appropriate permissions
#   - Repository admin access for enabling auto-merge

set -euo pipefail

# Configuration
ORG="zircote"
EXCLUDED_REPOS=("swagger-php")
WORKFLOW_FILE=".github/workflows/dependabot-automerge.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../templates/dependabot-automerge.yml"
COMMIT_MESSAGE="ci: add Dependabot auto-merge workflow

Enables automatic approval and merging of Dependabot PRs.
Uses centralized workflow from zircote/.github."

# Parse arguments
DRY_RUN=false
SINGLE_REPO=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --repo)
            SINGLE_REPO="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_dry() { echo -e "${YELLOW}[DRY-RUN]${NC} $1"; }

# Check if repo is excluded
is_excluded() {
    local repo="$1"
    for excluded in "${EXCLUDED_REPOS[@]}"; do
        if [[ "$repo" == "$excluded" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if workflow already exists in repo
workflow_exists() {
    local repo="$1"
    gh api "repos/$ORG/$repo/contents/$WORKFLOW_FILE" --silent 2>/dev/null && return 0
    return 1
}

# Enable auto-merge setting on repository
enable_automerge() {
    local repo="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would enable auto-merge on $ORG/$repo"
        return 0
    fi

    if gh api "repos/$ORG/$repo" --method PATCH --field allow_auto_merge=true --silent 2>/dev/null; then
        log_success "Enabled auto-merge on $ORG/$repo"
        return 0
    else
        log_warning "Could not enable auto-merge on $ORG/$repo (may require admin access)"
        return 1
    fi
}

# Add workflow file to repository
add_workflow() {
    local repo="$1"
    local content
    content=$(base64 < "$TEMPLATE_FILE")

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would add workflow to $ORG/$repo"
        return 0
    fi

    # Get default branch
    local default_branch
    default_branch=$(gh api "repos/$ORG/$repo" --jq '.default_branch')

    # Create or update file
    if gh api "repos/$ORG/$repo/contents/$WORKFLOW_FILE" \
        --method PUT \
        --field message="$COMMIT_MESSAGE" \
        --field content="$content" \
        --field branch="$default_branch" \
        --silent 2>/dev/null; then
        log_success "Added workflow to $ORG/$repo"
        return 0
    else
        log_error "Failed to add workflow to $ORG/$repo"
        return 1
    fi
}

# Process a single repository
process_repo() {
    local repo="$1"

    log_info "Processing $ORG/$repo..."

    # Check if excluded
    if is_excluded "$repo"; then
        log_warning "Skipping $repo (excluded)"
        return 0
    fi

    # Check if workflow already exists
    if workflow_exists "$repo"; then
        log_warning "Workflow already exists in $repo, skipping"
        return 0
    fi

    # Enable auto-merge setting
    enable_automerge "$repo"

    # Add workflow file
    add_workflow "$repo"
}

# Main
main() {
    log_info "Dependabot Auto-Merge Rollout Script"
    log_info "Organization: $ORG"
    log_info "Excluded repos: ${EXCLUDED_REPOS[*]}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE - No changes will be made"
    fi

    echo ""

    # Verify template exists
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        log_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi

    # Process single repo or all repos
    if [[ -n "$SINGLE_REPO" ]]; then
        process_repo "$SINGLE_REPO"
    else
        # Get all non-archived repositories (paginated)
        # Detect if ORG is a user or organization and use appropriate API endpoint
        local repos
        local account_type
        account_type=$(gh api "users/$ORG" --jq '.type' 2>/dev/null || echo "Organization")

        if [[ "$account_type" == "User" ]]; then
            log_info "Detected $ORG as a user account"
            repos=$(gh api --paginate "users/$ORG/repos" --jq '.[] | select(.archived == false) | .name')
        else
            log_info "Detected $ORG as an organization"
            repos=$(gh api --paginate "orgs/$ORG/repos" --jq '.[] | select(.archived == false) | .name')
        fi

        local total
        total=$(echo "$repos" | wc -l | tr -d ' ')
        local count=0
        local success=0
        local skipped=0
        local failed=0

        log_info "Found $total repositories"
        echo ""

        while IFS= read -r repo; do
            ((count++))
            echo "[$count/$total] Processing $repo..."

            if is_excluded "$repo"; then
                log_warning "  Skipping (excluded)"
                ((skipped++))
                continue
            fi

            if workflow_exists "$repo"; then
                log_warning "  Workflow already exists, skipping"
                ((skipped++))
                continue
            fi

            if enable_automerge "$repo" && add_workflow "$repo"; then
                ((success++))
            else
                ((failed++))
            fi

            echo ""
        done <<< "$repos"

        # Summary
        echo ""
        log_info "========== Summary =========="
        log_info "Total repositories: $total"
        log_success "Successfully updated: $success"
        log_warning "Skipped: $skipped"
        if [[ $failed -gt 0 ]]; then
            log_error "Failed: $failed"
        fi
    fi
}

main "$@"
