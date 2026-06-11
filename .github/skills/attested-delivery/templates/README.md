# Workflow Templates — the architecture, baked in

These are complete, parameterized copies of the canonical attested-delivery
workflows. The skill is **self-contained**: materializing the architecture
in any organization requires nothing beyond this directory — no access to
any upstream repo.

## Materialization

1. Copy every `*.yml` here into the target central repo's
   `.github/workflows/` (conventionally the org's `.github` repository).
2. Replace the two placeholder tokens in all files:
   - `__ORG__` → the GitHub owner exactly as written (e.g. `MyOrg`)
   - `__org__` → the owner lowercased (registry namespaces, e.g.
     `ghcr.io/myorg/...`)
   ```sh
   sed -i -e 's/__ORG__/MyOrg/g' -e 's/__org__/myorg/g' .github/workflows/*.yml
   ```
3. Commit to the central repo's default branch and record the commit SHA —
   it is the pin every caller uses (`uses: <owner>/.github/.github/workflows/<wf>.yml@<sha>`).
4. Private/internal central repo only: set the Actions access level so
   other repos can call the workflows
   (`gh api -X PUT repos/<owner>/.github/actions/permissions/access -f access_level=organization`).
   Public central repos skip this — public workflows are callable by anyone.

Notes:
- `build-attest.yml` calls `sign-and-attest.yml` by **local** reference
  (`./.github/workflows/...`), so the pair stays consistent automatically.
- Every third-party action inside the templates is pinned to a full commit
  SHA with the version as a comment; Dependabot's `github-actions`
  ecosystem keeps them current after materialization.
- `mirror-images.yml` is only needed under a single-registry policy; its
  matrix lists example images — edit to the target's actual base images.
- `promote.yml` / `promote-prod.yml` / `dora-emit.yml` apply only to
  deploying targets (skill Phase 5).

## Provenance and freshness

These templates were validated end-to-end in a production rollout (build →
sign-and-attest → fail-closed verify → publish, with independent AT-05/AT-06
verification of the published digest) before being baked into the skill.
This directory is the canonical source.

Skill maintainers: if this repository also hosts materialized copies under
`.github/workflows/`, refresh the templates by re-parameterizing them
(`sed -e 's/<Owner>/__ORG__/g' -e 's/<owner>/__org__/g'`) after any change,
so template and live workflow never drift.
