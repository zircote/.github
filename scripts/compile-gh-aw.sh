#!/usr/bin/env bash
# Generic compile + patch for any gh-aw workflow in .github repos.
# Workaround for gh-aw bug github/gh-aw#18711: runtime-import fails
# for workflows in repos named .github (doubled .github path).
#
# Usage: compile-gh-aw.sh <workflow-name>
set -euo pipefail

export WORKFLOW_NAME="${1:?Usage: compile-gh-aw.sh <workflow-name>}"

# Step 1: Compile
gh aw compile "$WORKFLOW_NAME"

# Step 2: Replace the runtime-import line with the properly indented
# prose body. The content sits inside a YAML block scalar (run: |).
python3 <<'PYEOF'
import os, sys

workflow = os.environ["WORKFLOW_NAME"]
lock_path = f".github/workflows/{workflow}.lock.yml"
md_path = f".github/workflows/{workflow}.md"

lock = open(lock_path, "r").read()

marker = f"{{{{#runtime-import .github/.github/workflows/{workflow}.md}}}}"
if marker not in lock:
    print("WARNING: runtime-import marker not found", file=sys.stderr)
    sys.exit(0)

# Extract prose body from the .md (everything after second ---)
with open(md_path) as f:
    lines = f.readlines()
fence_count = 0
body_lines = []
for line in lines:
    if line.strip() == "---":
        fence_count += 1
        continue
    if fence_count >= 2:
        body_lines.append(line.rstrip("\n"))

# Find the indentation of the marker line in the lock file
for lock_line in lock.split("\n"):
    stripped = lock_line.lstrip()
    if marker in stripped:
        indent = " " * (len(lock_line) - len(stripped))
        break
else:
    indent = "          "  # fallback: 10 spaces

# Indent the body to match
indented = "\n".join(indent + bl if bl.strip() else "" for bl in body_lines)

lock = lock.replace(indent + marker, indented)
open(lock_path, "w").write(lock)
print(f"Patched {lock_path}: inlined prompt body ({len(indented)} chars)")
PYEOF
