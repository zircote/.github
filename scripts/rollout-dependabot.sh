#!/usr/bin/env bash
# Rollout dependabot.yml + automerge workflow to zircote repositories.
#
# Usage:
#   ./scripts/rollout-dependabot.sh [--dry-run] [--repo REPO]
#
# For each repo missing dependabot config, this script:
#   1. Pushes a language-appropriate .github/dependabot.yml
#   2. Pushes the dependabot-automerge.yml workflow (calls reusable workflow)
#   3. Enables the "Allow auto-merge" repository setting
#
# Requirements:
#   - gh CLI authenticated with repo contents:write + admin permission

set -euo pipefail

ORG="zircote"
EXCLUDED_REPOS=("php-swagger" "swagger-php")
FILE_PATH=".github/dependabot.yml"
AUTOMERGE_PATH=".github/workflows/dependabot-automerge.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMERGE_TEMPLATE="$SCRIPT_DIR/../templates/dependabot-automerge.yml"
COMMIT_MESSAGE="chore: add Dependabot configuration

Enable automated dependency updates for this repository."
AUTOMERGE_COMMIT="ci: add Dependabot auto-merge workflow

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

has_dependabot() {
	gh api "repos/$ORG/$1/contents/$FILE_PATH" --silent 2>/dev/null
}

has_automerge_workflow() {
	gh api "repos/$ORG/$1/contents/$AUTOMERGE_PATH" --silent 2>/dev/null
}

enable_automerge_setting() {
	local repo="$1"
	if gh api "repos/$ORG/$repo" --method PATCH --field allow_auto_merge=true --silent 2>/dev/null; then
		log_success "  auto-merge setting enabled"
		return 0
	else
		log_warning "  could not enable auto-merge setting (may need admin)"
		return 1
	fi
}

push_automerge_workflow() {
	local repo="$1"
	if has_automerge_workflow "$repo"; then
		log_warning "  automerge workflow already exists"
		return 0
	fi

	local content default_branch
	content=$(base64 <"$AUTOMERGE_TEMPLATE")
	default_branch=$(gh api "repos/$ORG/$repo" --jq '.default_branch')

	if gh api "repos/$ORG/$repo/contents/$AUTOMERGE_PATH" \
		--method PUT \
		--field message="$AUTOMERGE_COMMIT" \
		--field content="$content" \
		--field branch="$default_branch" \
		--silent 2>/dev/null; then
		log_success "  automerge workflow pushed"
		return 0
	else
		log_error "  failed to push automerge workflow"
		return 1
	fi
}

# Generate dependabot.yml content based on language.
# All configs follow org conventions: weekly on Monday 09:00 America/Chicago,
# chore(deps) prefix, zircote reviewer, grouped minor/patch updates.
generate_config() {
	local lang="$1"
	local ecosystem="" label=""

	case "$lang" in
	Python | "Jupyter Notebook")
		ecosystem="pip"
		label="python"
		;;
	Rust)
		ecosystem="cargo"
		label="rust"
		;;
	Go)
		ecosystem="gomod"
		label="go"
		;;
	TypeScript | JavaScript)
		ecosystem="npm"
		label="npm"
		;;
	Java | Kotlin)
		ecosystem="gradle"
		label="java"
		;;
	Ruby)
		ecosystem="bundler"
		label="ruby"
		;;
	PHP)
		ecosystem="composer"
		label="php"
		;;
	Elixir)
		ecosystem="mix"
		label="elixir"
		;;
	Swift)
		ecosystem="swift"
		label="swift"
		;;
	"")
		ecosystem=""
		label=""
		;;
	*)
		ecosystem=""
		label=""
		;;
	esac

	cat <<YAML
version: 2
updates:
YAML

	# Language-specific ecosystem (if applicable)
	if [[ -n "$ecosystem" ]]; then
		cat <<YAML
  - package-ecosystem: "$ecosystem"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "America/Chicago"
    open-pull-requests-limit: 10
    commit-message:
      prefix: "chore(deps)"
    labels:
      - "dependencies"
      - "$label"
    reviewers:
      - "zircote"
    groups:
      all-dependencies:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

YAML
	fi

	# Always include github-actions
	cat <<YAML
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "America/Chicago"
    open-pull-requests-limit: 5
    commit-message:
      prefix: "chore(deps)"
    labels:
      - "dependencies"
      - "github-actions"
    reviewers:
      - "zircote"
    groups:
      github-actions:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"
YAML
}

push_config() {
	local repo="$1" lang="$2"
	local config
	config=$(generate_config "$lang")
	local encoded
	encoded=$(echo "$config" | base64)

	local default_branch
	default_branch=$(gh api "repos/$ORG/$repo" --jq '.default_branch')

	if ! gh api "repos/$ORG/$repo/contents/$FILE_PATH" \
		--method PUT \
		--field message="$COMMIT_MESSAGE" \
		--field content="$encoded" \
		--field branch="$default_branch" \
		--silent 2>/dev/null; then
		log_error "$repo — failed to push $FILE_PATH"
		return 1
	fi
	log_success "$repo ($lang) -> dependabot.yml"

	# Also push automerge workflow and enable setting
	push_automerge_workflow "$repo"
	enable_automerge_setting "$repo"
	return 0
}

process_repo() {
	local repo="$1"

	if is_excluded "$repo"; then
		log_warning "$repo (excluded)"
		return 0
	fi

	if has_dependabot "$repo"; then
		log_warning "$repo (already has dependabot.yml)"
		return 0
	fi

	# Get primary language
	local lang
	lang=$(gh api "repos/$ORG/$repo" --jq '.language // ""')

	if [[ "$DRY_RUN" == "true" ]]; then
		local ecosystem=""
		case "$lang" in
		Python | "Jupyter Notebook") ecosystem="pip" ;;
		Rust) ecosystem="cargo" ;;
		Go) ecosystem="gomod" ;;
		TypeScript | JavaScript) ecosystem="npm" ;;
		Java | Kotlin) ecosystem="gradle" ;;
		Ruby) ecosystem="bundler" ;;
		PHP) ecosystem="composer" ;;
		Elixir) ecosystem="mix" ;;
		Swift) ecosystem="swift" ;;
		*) ecosystem="(github-actions only)" ;;
		esac
		log_dry "$repo — lang=$lang ecosystem=$ecosystem"
		return 0
	fi

	push_config "$repo" "$lang"
}

main() {
	log_info "Dependabot Config Rollout — org: $ORG"
	[[ "$DRY_RUN" == "true" ]] && log_warning "DRY-RUN MODE"
	echo ""

	if [[ -n "$SINGLE_REPO" ]]; then
		process_repo "$SINGLE_REPO"
	else
		local repos
		repos=$(gh api --paginate "users/$ORG/repos" \
			--jq '.[] | select(.archived == false and .fork == false) | .name' |
			sort)

		local total success=0 skipped=0 failed=0 count=0
		total=$(echo "$repos" | wc -l | tr -d ' ')
		log_info "Found $total repositories"
		echo ""

		while IFS= read -r repo; do
			((count++))

			if is_excluded "$repo"; then
				log_warning "[$count/$total] $repo (excluded)"
				((skipped++))
				continue
			fi

			local has_db=false has_am=false
			has_dependabot "$repo" && has_db=true
			has_automerge_workflow "$repo" && has_am=true

			if [[ "$has_db" == "true" && "$has_am" == "true" ]]; then
				log_warning "[$count/$total] $repo (fully configured)"
				((skipped++))
				continue
			fi

			local lang
			lang=$(gh api "repos/$ORG/$repo" --jq '.language // ""')

			if [[ "$DRY_RUN" == "true" ]]; then
				local eco="" actions=""
				case "$lang" in
				Python | "Jupyter Notebook") eco="pip" ;;
				Rust) eco="cargo" ;;
				Go) eco="gomod" ;;
				TypeScript | JavaScript) eco="npm" ;;
				Java | Kotlin) eco="gradle" ;;
				Ruby) eco="bundler" ;;
				PHP) eco="composer" ;;
				*) eco="github-actions only" ;;
				esac
				[[ "$has_db" == "false" ]] && actions="dependabot.yml"
				[[ "$has_am" == "false" ]] && actions="${actions:+$actions + }automerge"
				log_dry "[$count/$total] $repo — lang=$lang eco=$eco [$actions]"
				((skipped++))
			else
				local ok=true
				# Push dependabot.yml if missing
				if [[ "$has_db" == "false" ]]; then
					push_config "$repo" "$lang" || ok=false
				else
					# Already has dependabot, just add automerge
					log_info "[$count/$total] $repo — adding automerge only"
					push_automerge_workflow "$repo" || true
					enable_automerge_setting "$repo" || true
				fi
				if [[ "$ok" == "true" ]]; then
					((success++))
				else
					((failed++))
				fi
			fi
		done <<<"$repos"

		echo ""
		log_info "========== Summary =========="
		log_info "Total: $total"
		log_success "Updated: $success"
		log_warning "Skipped: $skipped"
		[[ $failed -gt 0 ]] && log_error "Failed: $failed"
	fi
}

main "$@"
