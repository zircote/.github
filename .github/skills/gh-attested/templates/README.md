# Templates — attested quality gates, parameterized

`__org__`-parameterized copies of the central reusable workflows, plus the
caller and repo-configuration artifacts. The skill is self-contained:
materializing the gate suite needs nothing beyond this directory.

## Workflow templates

`reusable-{sast-codeql,sca-osv,trivy,scorecard,vex,k6,zap,attest-scan,verify-gates}.yml`
are byte-for-byte copies of the live central workflows in
`zircote/.github/.github/workflows/`, with the single token `__org__`
substituted for the owner.

## Materialization

1. **Central repo** (one-time, if not already live): copy the `reusable-*.yml`
   into the org's central `.github` repo's `.github/workflows/`, substitute the
   token, commit to the default branch, record the SHA.
   ```sh
   # cross-platform in-place edit (GNU and BSD/macOS `sed -i` differ; perl is portable)
   perl -pi -e 's/__org__/MyOrg/g' .github/workflows/reusable-*.yml
   ```
   Public central repos are callable by anyone; private/internal ones need
   `gh api -X PUT repos/<owner>/.github/actions/permissions/access -f access_level=organization`.

2. **Target repo** (per repo being onboarded):
   - Copy `quality-gates-caller.yml` → `.github/workflows/quality-gates.yml`,
     substitute `__org__`, pin every `@<sha>` to the central repo's commit SHA,
     edit `languages:` and gate inputs for the repo.
   - Copy `dependabot.yml` and `CODEOWNERS` (substitute `__org__`).
   - Apply `ruleset.json` via `gh api -X POST repos/<o>/<r>/rulesets --input ruleset.json`
     after a diff-against-current preview (see references/repo-config.md).
   - Append `SECURITY-snippet.md` to the repo's `SECURITY.md`.
   - Read `secrets-and-vars.md` and set any optional secrets/variables yourself.

## Drift

These templates are the canonical parameterized source. If the live central
workflows change, regenerate the copies:
```sh
for wf in reusable-sast-codeql reusable-sca-osv reusable-trivy reusable-scorecard \
          reusable-vex reusable-k6 reusable-zap reusable-attest-scan reusable-verify-gates; do
  sed 's/zircote/__org__/g' ../../../workflows/${wf}.yml > ${wf}.yml
done
```
So template and live workflow never drift.

## Provenance and freshness

Every third-party action is pinned to a full commit SHA with the version as a
comment. `aquasecurity/trivy-action` is pinned to a maintainer-signed commit
dated after the March 2026 tag-compromise (CVE-2026-33634) — never replace it
with a tag.
