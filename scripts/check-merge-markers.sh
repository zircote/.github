#!/usr/bin/env bash
# Block commits that contain unresolved merge-conflict markers in staged files.
# Args: the staged file paths (passed by lefthook as {staged_files}).
# Checks only the unambiguous `<<<<<<<` / `>>>>>>>` line starts (a bare
# `=======` is a common Markdown/RST rule, so it is intentionally not flagged).
#
# Bypass in an emergency:  git commit --no-verify
set -euo pipefail
[ "$#" -eq 0 ] && exit 0

hits=$(grep -lE '^(<<<<<<<|>>>>>>>)' "$@" 2>/dev/null || true)
if [ -n "$hits" ]; then
  echo "Unresolved merge-conflict markers in:"
  echo "$hits" | sed 's/^/  /'
  echo "Resolve the conflicts, then re-stage and commit."
  exit 1
fi
