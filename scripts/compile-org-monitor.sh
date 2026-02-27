#!/usr/bin/env bash
# Compile org-monitor workflow.
# Thin wrapper around the generic compile-gh-aw.sh script.
set -euo pipefail
exec "$(dirname "$0")/compile-gh-aw.sh" org-monitor
