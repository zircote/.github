# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Attested delivery architecture** — nine centralized reusable workflows constituted from `HMH-ProdOps/.github@8f3b4d41a9aeedb430bd575020170ce0641dbd95` and parameterized for zircote: `build-attest.yml`, `sign-and-attest.yml` (SLSA Build L3 signing boundary), `verify-attestation.yml` (fail-closed gate), `promote.yml`, `promote-prod.yml`, `sbom-and-scan.yml`, `dora-emit.yml`, `pin-check.yml`, `mirror-images.yml`
- SECURITY.md "Verifying Release Artifacts" section with the full workstation verification command set (`gh attestation verify --signer-workflow`, `cosign verify`, SBOM/vuln attestation checks)
- **pin-check CI gate** (`pin-check-ci.yml`): every PR asserts all `uses:` references in `.github/workflows/` and `actions/` are pinned to full 40-char SHAs, calling the central `pin-check.yml` by SHA-pinned cross-repo reference
- **Stale Health Check workflow** (`stale-health-check.md`): weekly scan for stale issues (>30d), abandoned PRs (>7d), failing CI, and README staleness across all zircote repos (tracker: `stlhlt01`)
- **Dependency Ecosystem workflow** (`dependency-ecosystem.md`): weekly cross-repo dependency intelligence — Dependabot PR audit, version consistency, coverage gaps, and health scoring (tracker: `depeco01`)
- **Agent Health Monitor workflow** (`agent-health-monitor.md`): daily meta-monitoring of all gh-aw workflows for consecutive failures, missed schedules, and timeouts (tracker: `agenthm01`)
- **Generic compile script** (`scripts/compile-gh-aw.sh`): parameterized compile + patch for any gh-aw workflow, replacing hardcoded org-monitor references
- Three new automation labels: `stale-health`, `dep-ecosystem`, `agent-health`

### Fixed
- `dependabot-automerge.yml` called the reusable auto-merge workflow at the mutable `@main` ref; now uses the local-path form (same-commit, exempt from pin-check)
- attested-delivery skill templates: `dora-emit.yml` left `hmh.dora.*` metric names unparameterized (now `__org__.dora.*`); `build-attest.yml`/`sign-and-attest.yml` example image carried a `dqo/app` path (now `ghcr.io/__org__/app`)
- `promote-prod.yml` and `mirror-images.yml` regenerated from the generic templates — removes HMH-specific "CCAB" terminology (now "change-record") and repo-specific comments

### Changed
- `scripts/compile-org-monitor.sh` is now a thin wrapper delegating to `compile-gh-aw.sh`
- CLAUDE.md updated with workflow table (names, tracker IDs, schedules), generic compile instructions, and compile-all loop command
- Removed invalid `discussions: false` frontmatter rule from CLAUDE.md (not a valid gh-aw compiler property)

## [0.2.0] - 2025-01-20

### Added
- Organization-wide repository monitor gh-aw workflow (`org-monitor.md`, tracker: `orgmon01`)
- GitHub App integration (`zircote-org-monitor`) for cross-repo MCP access
- Compile + patch script for `.github` repo runtime-import bug workaround ([gh-aw#18711](https://github.com/github/gh-aw/issues/18711))
- gh-aw workflow conventions documented in CLAUDE.md

### Fixed
- Restore GitHub App config for cross-repo MCP access
- Properly indent inlined prompt body in lock file
- Inline prompt body to work around gh-aw#18711
- Correct org-monitor engine config and permissions

## [0.1.0] - 2025-01-15

### Added
- Reusable CI workflows for Python, TypeScript, Go, Rust, and Java
- Composite actions: `setup-python-uv`, `setup-node-pnpm`, `security-scan`, `release-notes`
- Reusable release workflow with semantic-release
- Reusable security scanning workflow (gitleaks + dependency audit)
- Reusable documentation deployment workflow
- Standardized label definitions (`labels.yml`) with github-label-sync support
- Dependabot auto-merge reusable workflow
- Organization profile README with badges and research section
- Community health files (SECURITY.md, CONTRIBUTING.md)
- Agent definitions and Copilot skills

[Unreleased]: https://github.com/zircote/.github/compare/main...HEAD
[0.2.0]: https://github.com/zircote/.github/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/zircote/.github/releases/tag/v0.1.0
