#!/usr/bin/env bash
# Sweep open Dependabot PRs across zircote repositories.
#
# For each open Dependabot PR:
#   - All checks pass  -> approve (if needed) + squash-merge
#   - Checks pending   -> skip (let CI finish)
#   - Checks failing   -> log for manual review
#
# Usage:
#   ./scripts/dependabot-sweep.sh [--dry-run] [--repo REPO]
#
# Requirements:
#   - gh CLI authenticated with repo + read:org scopes

set -euo pipefail

ORG="zircote"
EXCLUDED_REPOS=("php-swagger" "swagger-php")

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

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }
log_dry() { echo -e "${YELLOW}[DRY]${NC} $1"; }

is_excluded() {
	local repo="$1"
	for excluded in "${EXCLUDED_REPOS[@]}"; do
		[[ "$repo" == "$excluded" ]] && return 0
	done
	return 1
}

# Approve a PR if not already approved by this actor
approve_if_needed() {
	local repo="$1" pr_number="$2"

	# Check if already approved
	local approved
	approved=$(gh api "repos/$ORG/$repo/pulls/$pr_number/reviews" \
		--jq '[.[] | select(.state == "APPROVED")] | length' 2>/dev/null || echo "0")

	if [[ "$approved" -gt 0 ]]; then
		return 0
	fi

	gh pr review "$pr_number" --repo "$ORG/$repo" --approve --body "Automated approval by dependabot-sweep" 2>/dev/null
}

# Get PR check status: "pass", "fail", "pending"
get_check_status() {
	local repo="$1" pr_number="$2"

	local checks_output
	checks_output=$(gh pr checks "$pr_number" --repo "$ORG/$repo" 2>&1) || true

	if [[ -z "$checks_output" ]] || [[ "$checks_output" == "no checks reported"* ]]; then
		# No checks configured — treat as pass
		echo "pass"
		return
	fi

	local has_fail=false
	local has_pending=false

	while IFS= read -r line; do
		if echo "$line" | grep -qiE '\bfail\b|✗|X\b'; then
			has_fail=true
		elif echo "$line" | grep -qiE '\bpending\b|⏱|⏳|-\b'; then
			has_pending=true
		fi
	done <<<"$checks_output"

	if [[ "$has_fail" == "true" ]]; then
		echo "fail"
	elif [[ "$has_pending" == "true" ]]; then
		echo "pending"
	else
		echo "pass"
	fi
}

# Close and reopen a PR to re-trigger automerge workflow
close_reopen() {
	local repo="$1" pr_number="$2"
	gh pr close "$pr_number" --repo "$ORG/$repo" --comment "Closing to re-trigger automerge workflow (dependabot-sweep)" 2>/dev/null
	sleep 2
	gh pr reopen "$pr_number" --repo "$ORG/$repo" 2>/dev/null
}

process_pr() {
	local repo="$1" pr_number="$2" pr_title="$3"
	local label="$ORG/$repo#$pr_number"

	local status
	status=$(get_check_status "$repo" "$pr_number")

	case "$status" in
	pass)
		if [[ "$DRY_RUN" == "true" ]]; then
			log_dry "$label — would approve + squash-merge ($pr_title)"
		else
			approve_if_needed "$repo" "$pr_number"
			if gh pr merge "$pr_number" --repo "$ORG/$repo" --squash --delete-branch 2>/dev/null; then
				log_success "$label — merged ($pr_title)"
			else
				# Merge blocked (branch protection without --auto support?) — close/reopen to re-trigger automerge
				log_warning "$label — merge blocked, close/reopen to re-trigger automerge ($pr_title)"
				close_reopen "$repo" "$pr_number"
			fi
		fi
		;;
	pending)
		log_warning "$label — checks pending, skipping ($pr_title)"
		;;
	fail)
		log_error "$label — checks failing, needs manual review ($pr_title)"
		;;
	esac
}

process_repo() {
	local repo="$1"

	# Get open Dependabot PRs
	local prs
	prs=$(gh pr list --repo "$ORG/$repo" --author "app/dependabot" --state open \
		--json number,title --jq '.[] | "\(.number)\t\(.title)"' 2>/dev/null) || true

	if [[ -z "$prs" ]]; then
		return 0
	fi

	while IFS=$'\t' read -r pr_number pr_title; do
		process_pr "$repo" "$pr_number" "$pr_title"
	done <<<"$prs"
}

main() {
	log_info "Dependabot PR Sweep — org: $ORG"
	[[ "$DRY_RUN" == "true" ]] && log_warning "DRY-RUN MODE"
	echo ""

	if [[ -n "$SINGLE_REPO" ]]; then
		process_repo "$SINGLE_REPO"
	else
		local repos
		repos=$(gh api --paginate "orgs/$ORG/repos" --field type=all \
			--jq '.[] | select(.archived == false and .fork == false) | .name' |
			sort)

		local total
		total=$(echo "$repos" | wc -l | tr -d ' ')
		log_info "Scanning $total repositories for open Dependabot PRs"
		echo ""

		local count=0
		while IFS= read -r repo; do
			((count++))

			if is_excluded "$repo"; then
				continue
			fi

			process_repo "$repo"
		done <<<"$repos"
	fi

	echo ""
	log_info "========== Sweep Complete =========="
}

main "$@"
