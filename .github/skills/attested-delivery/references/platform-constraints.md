# Platform Constraints — symptom → cause → fix

Every entry below was discovered the hard way during the first end-to-end
production implementation of this architecture (which took five release
re-cuts).
The error messages rarely name the cause. Check this list FIRST when
anything in the chain fails.

## 1. Reusable workflows fail at startup: "workflow file issue", zero jobs

**Symptom:** caller run concludes `failure` instantly; `gh run view` shows
`"jobs": []` and "This run likely failed because of a workflow file issue" —
but the YAML is valid.
**Cause:** the central repo's Actions access level is `none` (the default
for private/internal repos). No other repo can resolve its reusable
workflows.
**Fix:**
```sh
gh api -X PUT repos/<org>/.github/actions/permissions/access -f access_level=organization
```

## 2. GHCR rejects GitHub App installation tokens

**Symptom:** `docker login` succeeds with an App installation token, but
every registry operation 404s: `expected 200, received 404` fetching a
manifest that demonstrably exists, `HEAD ... 404 Not Found` from cosign.
**Cause:** ghcr.io's data plane does not honor App installation tokens for
existing repo-linked packages — GHCR's supported credentials are the
workflow's `GITHUB_TOKEN` or a PAT. GHCR masks unauthorized reads as 404
(resource hiding), so it looks like a missing image, not an auth failure.
**Fix:** use the run's `GITHUB_TOKEN` (preferred: ephemeral, repo-scoped)
or a PAT for all ghcr push/pull. Keep App identities for the GitHub API
control plane, where they work.

## 3. `attest-build-provenance` push-to-registry needs the run's own GITHUB_TOKEN

**Symptom:** `OCIError: Error uploading artifact to container registry` or
`No credentials found for registry ghcr.io` from the provenance step.
**Cause:** the action's OCI client only supports the workflow's own
`GITHUB_TOKEN` for GHCR (actions/attest-build-provenance#73). A docker
login with any other credential breaks it.
**Fix:** one `docker/login-action` with `github.actor` /
`secrets.GITHUB_TOKEN` before the provenance step. The same login serves
the cosign pushes after it.

## 4. `gh attestation verify --repo` fails against centrally-signed images

**Symptom:** `Error: verifying with issuer "GitHub, Inc."` (terse, ~4s),
locally reproducible, even though the attestation is valid.
**Cause:** `--repo X` asserts the certificate SAN is a workflow **in X**.
Under SLSA L3 the SAN is the *central signer workflow*
(`<org>/.github/.github/workflows/sign-and-attest.yml@<sha>`), so the SAN
policy fails by design. Separately: `--cert-identity-regexp` and
`--cert-oidc-issuer` are **cosign** flags — `gh` rejects them with a usage
dump.
**Fix:** assert source repo and signer separately:
```sh
gh attestation verify oci://<image>@<digest> \
  --repo <org>/<repo> \
  --signer-workflow <org>/.github/.github/workflows/sign-and-attest.yml \
  --predicate-type https://slsa.dev/provenance/v1
```

## 5. cargo-audit / cargo-deny advisory-db collision (Rust)

**Symptom:** `couldn't fetch advisory database: ... Refusing to initialize
the non-empty directory as '~/.cargo/advisory-db'` — only in CI, never
locally.
**Cause:** both tools default to `~/.cargo/advisory-db`. cargo-deny's
fetch format is not a plain git clone; cargo-audit refuses to clone over
it. Locally the dir was usually created by cargo-audit first, which deny
can read — so the order dependency hides until both share one fresh runner.
**Fix:** in a shared job, run `cargo audit` (git clone) before
`cargo deny check`. Comment the ordering so nobody "tidies" it.

## 6. Registry login must precede Buildx setup

**Symptom:** builder-image or base-image pulls run anonymously — failing
for internal mirror images, or hitting Docker Hub anonymous rate
limits/timeouts (`registry-1.docker.io ... Client.Timeout exceeded`).
**Cause:** `docker/setup-buildx-action` pulls its BuildKit builder image at
setup time, with whatever credentials exist at that moment.
**Fix:** order `docker/login-action` before `setup-buildx-action` in every
building job. For registry-restricted orgs, also pin the builder image to a
mirror: `driver-opts: image=ghcr.io/<org>/mirror/buildkit:buildx-stable-1`.

## 7. Mirror package visibility

**Symptom:** consumer repos can't pull `ghcr.io/<org>/mirror/*` with
`GITHUB_TOKEN` even though the images exist.
**Cause:** GHCR packages default to private, scoped to the repo whose
workflow pushed them.
**Fix:** set mirror packages to **internal** (org-wide pull) or public
(they mirror public images anyway). Verify with
`gh api orgs/<org>/packages/container/mirror%2F<name> --jq .visibility`.

## 8. Default branch: API only

**Symptom:** PRs opened against the wrong base; tags cut from the wrong
branch.
**Cause:** local `origin/HEAD` is set at clone time and never updated by
`git fetch`; org repos increasingly use `develop` or other defaults.
**Fix:** `gh api repos/<o>/<r> --jq .default_branch` before branching;
`git remote set-head origin -a` to repair the local pointer.

## 9. PR-only branch sync needs a sync branch

**Symptom:** a back-merge PR with head `main`, base `develop` is
permanently `BEHIND` under "require branches to be up to date".
**Cause:** `main` will always lack develop-only commits; the strict
up-to-date rule can never be satisfied by a branch-headed PR in the
back-merge direction.
**Fix:** create a sync branch from the base, merge the source into it,
PR the sync branch. Treat back-merge as a standing post-release step —
every PR-only promotion merge creates the debt again.

## 10. Auto-update-branch races force-pushes

**Symptom:** `push --force-with-lease` rejected with "stale info";
unexpected `Merge branch 'develop' into <pr-branch>` commits appear on PR
branches.
**Cause:** repo/org automation auto-merges the base into PR branches while
you work.
**Fix:** `git fetch` immediately before lease pushes; rebase onto the
fetched remote head; expect the content of auto-merge commits to already be
in your rebase.

## 11. Resolving a tag's digest for verification

**Symptom:** needing the digest for `oci://<image>@<digest>` commands when
only a tag is known; `docker manifest inspect` requires a local docker.
**Fix:** the GHCR package-versions API:
```sh
gh api 'orgs/<org>/packages/container/<name>/versions?per_page=20' \
  --jq '[.[] | select((.metadata.container.tags // []) | index("<tag>"))][0].name'
```

## 12. Check-run context names for reusable workflow calls

**Symptom:** a required status check never reports, blocking all merges.
**Cause:** the context for a reusable-workflow call is
`<caller job id> / <called job name>` (e.g. `pin-check / pin-check`), not
`<workflow name> / <job>`.
**Fix:** read the context name off an actual run before adding it to
branch protection; update protection in the same motion as renaming any
job that is a required check.
