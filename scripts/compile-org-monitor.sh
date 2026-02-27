#!/usr/bin/env bash
# Compile org-monitor.md and patch the lock file to inline the prompt body.
# Workaround for gh-aw bug github/gh-aw#18711: runtime-import fails
# for workflows in repos named .github (doubled .github path).
set -euo pipefail

# Step 1: Compile
gh aw compile org-monitor

# Step 2: Replace the runtime-import line with the properly indented
# prose body. The content sits inside a YAML block scalar (run: |).
python3 <<'PYEOF'
import sys

lock_path = ".github/workflows/org-monitor.lock.yml"
md_path = ".github/workflows/org-monitor.md"

lock = open(lock_path, "r").read()

marker = "{{#runtime-import .github/.github/workflows/org-monitor.md}}"
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
