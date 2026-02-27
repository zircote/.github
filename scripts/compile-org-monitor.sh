#!/usr/bin/env bash
# Compile org-monitor.md and patch the lock file to inline the prompt body.
# Workaround for gh-aw bug github/gh-aw#18711: runtime-import fails
# for workflows in repos named .github (doubled .github path).
set -euo pipefail

WORKFLOW="org-monitor"
LOCK=".github/workflows/${WORKFLOW}.lock.yml"
MD=".github/workflows/${WORKFLOW}.md"

# Step 1: Compile
gh aw compile "$WORKFLOW"

# Step 2: Extract prose body (everything after the closing ---)
BODY=$(awk 'BEGIN{n=0} /^---$/{n++; if(n==2){found=1; next}} found{print}' "$MD")

# Step 3: Replace the runtime-import line with the inlined body.
# The runtime-import line looks like:
#   {{#runtime-import .github/.github/workflows/org-monitor.md}}
python3 -c "
import sys

lock = open('$LOCK', 'r').read()
body = open('/dev/stdin', 'r').read()

marker = '{{#runtime-import .github/.github/workflows/${WORKFLOW}.md}}'
if marker not in lock:
    print('WARNING: runtime-import marker not found — lock file may already be patched or format changed', file=sys.stderr)
    sys.exit(0)

lock = lock.replace(marker, body)
open('$LOCK', 'w').write(lock)
print(f'Patched {\"$LOCK\"}: inlined prompt body ({len(body)} chars)')
" <<<"$BODY"
