# zircote Platform Documentation

Documentation for the centralized tooling this repository provides to every
`zircote/*` repository: the attested-delivery workflows, reusable CI/CD
workflows, and shared automation.

The docs follow the [Diátaxis](https://diataxis.fr/) framework — four kinds of
documentation for four kinds of need:

| You want to... | Read |
| --- | --- |
| Learn the system hands-on | [Tutorials](#tutorials) |
| Get a specific task done | [How-to guides](#how-to-guides) |
| Look up exact inputs, outputs, and behavior | [Reference](#reference) |
| Understand why it works this way | [Explanation](#explanation) |

## Tutorials

- [Your first attested release](tutorials/first-attested-release.md) — build,
  sign, attest, and verify a container image end to end using the centralized
  workflows.

## How-to guides

- [Onboard a repo to attested delivery](how-to/onboard-a-repo-to-attested-delivery.md)
- [Onboard a repo to attested quality gates](how-to/onboard-a-repo-to-attested-quality-gates.md)
- [Enforce action SHA pinning](how-to/enforce-action-sha-pinning.md)
- [Generate an SBOM and vulnerability scan](how-to/generate-sbom-and-vuln-scan.md)
- [Emit DORA deployment metrics](how-to/emit-dora-deployment-metrics.md)
- [Enforce admission of attested images](how-to/enforce-admission-of-attested-images.md) (Kubernetes/Kyverno and pre-deploy gates)

For coding agents (Claude Code, Copilot, gh-aw), the
[attested-delivery skill](../.github/skills/attested-delivery/SKILL.md)
packages all of the above — architecture, platform constraints, caller recipes
with baked-in workflow templates, rollout checklist, and verification — as an
executable, fully self-contained onboarding protocol for any org or repo.

## Reference

- [Reusable workflows](reference/workflows.md) — every centralized
  attested-delivery workflow: inputs, outputs, secrets, permissions.
- Language CI, release, security, and docs workflows are summarized in
  [CLAUDE.md](../CLAUDE.md) and the [repo README](../README.md#reusable-workflows).

## Explanation

- [Why attested delivery](explanation/attested-delivery.md) — the promotion
  invariant, the signing-isolation boundary, admission-time enforcement, and
  the change-record gate.

## Project plans

Plans are working project artifacts, not user documentation, and sit outside
the Diátaxis quadrants:

- [Attested delivery — rollout status](attested-delivery/rollout-status.md)

## Other content

- [Presentations](presentations/README.md) — the slide-deck generation system.

## Coverage matrix

| Tool / component | Tutorial | How-to | Reference | Explanation |
| --- | --- | --- | --- | --- |
| `build-attest.yml` | Yes | Yes | Yes | Yes |
| `sign-and-attest.yml` | Yes | Yes | Yes | Yes |
| `verify-attestation.yml` | Yes | Yes | Yes | Yes |
| `promote.yml` / `promote-prod.yml` | — | Yes | Yes | Yes |
| `sbom-and-scan.yml` | — | Yes | Yes | — |
| `dora-emit.yml` | — | Yes | Yes | Yes |
| `pin-check.yml` | — | Yes | Yes | — |
| Admission enforcement (Kyverno / pre-deploy gate) | — | Yes | — | Yes |
