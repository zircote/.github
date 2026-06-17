#!/usr/bin/env bash
# Local mirror of the CI pin-check gate (.github/workflows/pin-check.yml):
# assert every GitHub Actions `uses:` is pinned to a full 40-char commit SHA.
#
# Scans the SAME dirs as pin-check-ci.yml (.github/workflows + actions) so it
# does not false-positive on the illustrative `uses: …@v6` lines inside
# .github/skills/**/*.md, which are documentation, not executable.
#
# Local reusable-workflow calls (`uses: ./...`) and digest-pinned container
# actions (`uses: docker://...@sha256:...`) are exempt.
#
# Bypass in an emergency:  git push --no-verify
set -euo pipefail

rc=0
for SCAN_DIR in .github/workflows actions; do
  [ -d "$SCAN_DIR" ] || continue
  while IFS= read -r hit; do
    file="${hit%%:*}"; rest="${hit#*:}"
    lineno="${rest%%:*}"; content="${rest#*:}"
    # Isolate the `uses:` value: drop up to `uses:`, ltrim, keep the first token
    # only — so inline comments cannot influence the check.
    value="${content#*uses:}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%%[[:space:]]*}"
    case "$value" in
      ./*) continue ;;                  # local reusable workflow
      docker://*@sha256:*) continue ;;  # digest-pinned container action
    esac
    ref="${value##*@}"
    if ! printf '%s' "$ref" | grep -Eq '^[0-9a-f]{40}$'; then
      echo "  ✗ ${file}:${lineno}  unpinned: ${value}"
      rc=1
    fi
  done < <(grep -rnE '^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*[^[:space:]]+@' "$SCAN_DIR" || true)
done

if [ "$rc" -ne 0 ]; then
  echo ""
  echo "ERROR: unpinned action references found — the CI pin-check gate will reject this push."
  echo "Fix: replace each @tag with the action's full 40-char commit SHA (keep the version as a comment)."
  echo "Bypass (emergency): git push --no-verify"
else
  echo "pin-check: all action references under .github/workflows and actions are SHA-pinned."
fi
exit "$rc"
