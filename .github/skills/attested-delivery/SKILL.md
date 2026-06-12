---
name: attested-delivery
description: Constitute and materialize the attested release architecture — signed, SLSA-attested, fail-closed-verified releases — in any organization or repository. USE THIS SKILL when user says "onboard to attested delivery", "set up release signing", "SLSA provenance", "attest releases", "constitute the attested architecture", "pin check", or "verify release attestations".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Attested Delivery — Architect & Onboarding Skill

## Purpose

Constitute and materialize the attested release architecture — signed,
SLSA-attested, fail-closed-verified releases — in any organization or
repository, from this skill's self-contained workflow templates.

## Triggers

- "onboard this repo to attested delivery"
- "set up release signing / SLSA provenance"
- "constitute the attested architecture in [org]"
- "migrate CI to SHA-pinned actions with a required pin check"
- "verify release attestations"

## Usage

Run Phase 0 (Discovery) to detect the operating mode, then follow the phase
protocol below. Mode B constitutes a new org from `templates/`; Mode A wires
a consumer repo against an existing central repo. Do not proceed past a
failing phase gate.

## Architecture Invariant

You are implementing a proven supply-chain architecture. The invariant:
**an artifact reaches consumers only if it is byte-identical to what was
validated, carries attestations (SLSA provenance, signature, SBOM, vuln
report) that re-verify at every hop, and publication is gated on fail-closed
verification.** Signing runs in a centralized reusable workflow the calling
repo cannot modify — under SLSA Build L3 the certificate identity (SAN) is
the central signer, not the artifact repo.

The reference implementation IS this skill's `templates/` directory —
nine complete, parameterized workflows (`build-attest`, `sign-and-attest`,
`verify-attestation`, `promote`, `promote-prod`, `sbom-and-scan`,
`dora-emit`, `pin-check`, `mirror-images`), validated end-to-end in a
production rollout before being baked in. The skill is fully
self-contained: no external repository access is required to apply it.
For the **binaries/bundles flow** (no container), the reference
implementations are `zircote/rlm-rs` and `zircote/rust-template`
(`release.yml`, `publish.yml`, `package-homebrew.yml`) — proven via
released versions and dispatch dry-runs; the full recipe is in
`references/integration-recipes.md` (recipe D).

**Before doing anything else**, read `references/platform-constraints.md` in
this skill. Every entry was paid for with a failed release; violating any of
them produces failures whose error messages do not name the cause.

## Operating modes — detect, then branch

Run Phase 0 (Discovery) first. It determines the mode:

- **Mode A — consumer repo, architecture exists.** The target org already
  has the central workflows. Wire the repo as a caller, pinned by the full
  40-char commit SHA of the org's central repo. Skip Phase 1 except gap
  checks.
- **Mode B — constitute a new org.** Any org (or personal account)
  without the architecture gets its own copy, **from this skill's bundled
  `templates/` directory** — the skill is self-contained and requires no
  access to any upstream repo. Follow `templates/README.md`: copy the
  workflows into the target's central repo (conventionally
  `<owner>/.github`), substitute the `__ORG__` / `__org__` placeholder
  tokens, commit, record the SHA, set the Actions access level if the
  central repo is private/internal (public repos skip this). Then proceed
  as Mode A for the pilot repo. **Never** wire cross-org `uses:`
  references to another org's central repo.


## Phase protocol

Each phase ends with a verify gate. Do not proceed past a failing gate.

### Phase 0 — Discovery (read-only)

1. **Default branch via API**: `gh api repos/<o>/<r> --jq .default_branch`.
   Never trust local `origin/HEAD` (constraint 8). All PRs target it.
2. **Language/build system**: lockfile + manifest detection (Cargo.toml,
   package.json, pyproject.toml, go.mod, pom.xml/build.gradle). Load the
   matching row of `references/integration-recipes.md`.
3. **Container shape** — drives the wiring decision table below: no
   container build / single-arch simple build / multi-arch matrix build /
   build already pushes by digest.
4. **Registry posture**: does org policy restrict registry traffic (e.g.
   ghcr-only)? Inventory every external registry contact: base images in
   Dockerfiles, the BuildKit builder image pulled by
   `docker/setup-buildx-action`, scanner DBs.
5. **Deploy target**: none / Kubernetes / ECS / Lambda. None ⇒ Phase 5
   (promotion/admission/DORA) is out of scope; record that explicitly.
6. **Existing CI**: workflows, signing stubs (cosign/slsa placeholder
   workflows are common), action pinning state (count tag-pinned `uses:`),
   branch protection contexts, environments, auto-merge automations.
7. **Org plumbing**: central repo's
   `repos/<o>/.github/actions/permissions/access` level; GHCR package
   visibility defaults.

Gate: a written discovery summary naming mode, wiring row, in-scope phases.

### Phase 1 — Constitute (org level; Mode B, or Mode A gap-fill)

1. Central workflows present on the org's central repo default branch;
   record the full HEAD SHA — it is the pin for every caller.
2. `gh api -X PUT repos/<o>/<central>/actions/permissions/access -f access_level=organization`
   — without this every cross-repo `uses:` fails at startup with
   "workflow file issue" and zero jobs (constraint 1).
3. If registry policy is ghcr-only: materialize `mirror-images.yml`,
   dispatch it once, confirm the mirror packages exist with **internal** (or
   public) visibility so org repos' `GITHUB_TOKEN` can pull (constraint 7).
4. Only if promotion is in scope: a change-record issue convention for the
   gate (approval label, digest recorded in the issue body; optionally a
   Projects v2 board and a `CHANGE_RECORD_TOKEN` secret with project read
   access — `GITHUB_TOKEN` cannot read Projects v2).

Gate: a scratch caller workflow (or the pilot's first PR) resolves the
reusable workflow without startup failure.

### Phase 2 — Materialize (repo level)

Wiring decision table:

| Build shape | Wiring |
| --- | --- |
| No container build yet | Single `build-attest.yml` call — builds, pushes to GHCR by digest, signs/attests, self-verifies |
| Build already pushes by digest | Call `sign-and-attest.yml` directly with `image-name` + `image-digest`, then `verify-attestation.yml` |
| Multi-arch matrix build | Keep the matrix; add a manifest-digest capture step after the manifest merge; then sign/verify as above. Exact recipe in `references/integration-recipes.md` |
| Binaries/bundles only (no image) | Full recipe D: meta (var-driven via `cargo metadata`) → build matrix with build-time `attest-build-provenance` and `{bin}-{version}-{platform}` names → test/audit gates → SBOM attest → fail-closed verify BEFORE the tag-gated release; crates.io via Trusted Publishing + registry byte-compare + attest; templates ship `publish = false` as the channel gate |

Required elements, all shapes:
1. **Digest capture** (matrix shape): after `docker buildx imagetools create`,
   inspect the pushed tag and emit `image-digest` as a job output.
2. **Fail-closed verify job** between signing and publication:
   `verify-attestation.yml` with `image-ref`, `attestation-repo: <o>/<r>`.
3. **Publication gated on verify**: the GitHub Release / publish job adds
   the verify job to `needs:` — a tag publishes nothing unsigned.
4. **pin-check as a CI job** (the documented required implementation — not
   a standalone advisory workflow): job in the repo's CI workflow calling
   the central `pin-check.yml`, later made a required status check. Migrate
   every `uses:` to full 40-char SHAs with the version as a trailing
   comment. Channel-encoding actions (e.g. `dtolnay/rust-toolchain@stable`)
   need an explicit input (`toolchain: stable`) once SHA-pinned, because
   the SHA no longer encodes the channel.
5. **Registry login before Buildx setup** in every job that builds, so the
   builder image and base image pulls are authenticated (constraint 6).
6. **SECURITY.md** "Verifying Release Artifacts" section — the exact
   commands from `references/verification.md`, with `--signer-workflow`.
7. **Release dry-run**: add `workflow_dispatch` to the release workflow and
   tag-gate the publish jobs (`if: startsWith(github.ref, 'refs/tags/')`),
   so the build → sign → verify chain is exercisable without cutting a
   version. The first production onboarding took five release re-cuts because
   this didn't exist; do not skip it.
8. CHANGELOG entry per the repo's conventions.

Gate: `actionlint` clean; PR opens; pipeline green including
`pin-check / pin-check`.

### Phase 3 — Protection & branch model

1. Required status checks: the CI gates plus `pin-check / pin-check`
   (context name = `<caller job id> / <called job name>`, NOT
   `<workflow> / <job>`).
2. If release promotion uses PR-only branches (e.g. develop → main), the
   promotion merge commit creates back-merge debt: sync it back via a
   **sync branch** PR (a `main`-headed PR can never satisfy a strict
   up-to-date rule — constraint 9). Document this as a standing
   post-release step.

### Phase 4 — Verify end-to-end

1. Dispatch the dry-run (or cut the first tag). The chain must show:
   build → manifest → sign-and-attest (provenance + cosign signature +
   SBOM + vuln report as OCI referrers, then self-verify) → verify
   (fail-closed) → publish (tag runs only).
2. Run every command in `references/verification.md` **independently**
   against the published digest — in-pipeline success is not the
   acceptance test. AT-05 and AT-06 from
   `references/rollout-checklist.md` must pass from a workstation.

### Phase 5 — Conditional extensions (only when Phase 0 found a deploy target)

- `promote.yml` between environments (referrer-carrying `cosign copy` +
  post-copy re-verify); `promote-prod.yml` behind the change-record gate —
  an approved GitHub issue whose body records the promoting digest
  (issue↔digest equality is always asserted; add `project-number` for a
  Projects v2 `Status` assertion).
- `dora-emit.yml` (deployment = production digest promotion), with
  `if: always()` so failures emit too.
- Admission enforcement (Kyverno/Gatekeeper for k8s, pre-deploy verify for
  ECS/Lambda) — design references in the central repo's
  `docs/how-to/enforce-admission-of-attested-images.md`.

## Hard rules (evidence in references/platform-constraints.md)

1. GHCR data plane: `GITHUB_TOKEN` or PAT only — GitHub App installation
   tokens are rejected with resource-hiding 404s.
2. `attest-build-provenance` push-to-registry: only the run's own
   `GITHUB_TOKEN` works.
3. `gh attestation verify` under SLSA L3: `--repo <artifact-repo>` alone
   FAILS (SAN is the central signer) — always add
   `--signer-workflow <org>/.github/.github/workflows/sign-and-attest.yml`.
   `--cert-identity-regexp` / `--cert-oidc-issuer` are cosign flags; gh
   rejects them.
4. Central repo Actions access level must be `organization`.
5. Default branch from the API, never local `origin/HEAD`.
6. Login to the registry before `setup-buildx-action`.
7. cargo repos: run `cargo audit` before `cargo deny` when they share one
   job (`~/.cargo/advisory-db` clone-format collision).
8. Resolve a tag's digest for verification via the GHCR package-versions
   API, selecting on `.metadata.container.tags`.

## References

- `references/architecture.md` — invariant, components, all workflow interfaces
- `references/platform-constraints.md` — symptom → cause → fix for every trap
- `references/integration-recipes.md` — per-language rows + exact caller recipes
- `references/rollout-checklist.md` — phased rollout + acceptance tests AT-01…AT-08
- `references/verification.md` — the complete verification command set
