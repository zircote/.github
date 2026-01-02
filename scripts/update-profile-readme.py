#!/usr/bin/env python3
"""
Update profile README.md with dynamic activity sections.

Replaces content between marker comments:
- <!-- ACTIVE_REPOS_START --> ... <!-- ACTIVE_REPOS_END -->
- <!-- NEW_REPOS_START --> ... <!-- NEW_REPOS_END -->
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def generate_active_repos_section(repos: list[dict[str, Any]]) -> str:
    """Generate markdown table for top active repositories."""
    if not repos:
        return "_No active repositories found._"

    lines = [
        "| Repository | Description | Tech | Activity |",
        "|------------|-------------|------|----------|",
    ]

    for repo in repos:
        name = repo["name"]
        url = repo["url"]
        desc = repo["description"][:60] + "..." if len(repo["description"]) > 60 else repo["description"]
        desc = desc.replace("|", "\\|")  # Escape pipes
        lang = repo["language"]
        score = repo["score"]

        # Activity indicator based on score
        if score >= 0.7:
            activity = "🔥 Very Active"
        elif score >= 0.4:
            activity = "✨ Active"
        elif score >= 0.2:
            activity = "📈 Growing"
        else:
            activity = "💤 Stable"

        lines.append(f"| [{name}]({url}) | {desc} | {lang} | {activity} |")

    return "\n".join(lines)


def generate_new_repos_section(repos: list[dict[str, Any]]) -> str:
    """Generate markdown list for new repositories."""
    if not repos:
        return "_No new repositories in the last 90 days._"

    lines = []
    for repo in repos:
        name = repo["name"]
        url = repo["url"]
        desc = repo["description"] or "No description"
        desc = desc[:80] + "..." if len(desc) > 80 else desc
        lang = repo["language"]

        lines.append(f"- **[{name}]({url})** ({lang}) - {desc}")

    return "\n".join(lines)


def update_readme(
    readme_path: Path,
    top_repos: list[dict[str, Any]],
    new_repos: list[dict[str, Any]],
    dry_run: bool = False,
) -> bool:
    """
    Update README with new content between markers.

    Returns True if changes were made.
    """
    content = readme_path.read_text()
    original = content

    # Generate sections
    active_section = generate_active_repos_section(top_repos)
    new_section = generate_new_repos_section(new_repos)

    # Update timestamp
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    # Pattern for active repos section
    active_pattern = r"(<!-- ACTIVE_REPOS_START -->).*?(<!-- ACTIVE_REPOS_END -->)"
    active_replacement = rf"\1\n{active_section}\n\2"
    content = re.sub(active_pattern, active_replacement, content, flags=re.DOTALL)

    # Pattern for new repos section
    new_pattern = r"(<!-- NEW_REPOS_START -->).*?(<!-- NEW_REPOS_END -->)"
    new_replacement = rf"\1\n{new_section}\n\2"
    content = re.sub(new_pattern, new_replacement, content, flags=re.DOTALL)

    # Update timestamp marker if present
    timestamp_pattern = r"(<!-- LAST_UPDATED_START -->).*?(<!-- LAST_UPDATED_END -->)"
    timestamp_replacement = rf"\1 _Last updated: {timestamp}_ \2"
    content = re.sub(timestamp_pattern, timestamp_replacement, content, flags=re.DOTALL)

    if content == original:
        print("No changes needed")
        return False

    if dry_run:
        print("=== DRY RUN - Would update README with: ===")
        print(content)
        return True

    readme_path.write_text(content)
    print(f"Updated {readme_path}")
    return True


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Update profile README")
    parser.add_argument(
        "--readme-path",
        type=Path,
        default=Path("profile/README.md"),
        help="Path to README.md",
    )
    parser.add_argument(
        "--top-repos",
        help="JSON string of top repositories",
    )
    parser.add_argument(
        "--new-repos",
        help="JSON string of new repositories",
    )
    parser.add_argument(
        "--input-file",
        type=Path,
        help="JSON file with top_repos and new_repos keys",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without writing",
    )
    args = parser.parse_args()

    try:
        if args.input_file:
            data = json.loads(args.input_file.read_text())
            top_repos = data.get("top_repos", [])
            new_repos = data.get("new_repos", [])
        else:
            top_repos = json.loads(args.top_repos) if args.top_repos else []
            new_repos = json.loads(args.new_repos) if args.new_repos else []
    except json.JSONDecodeError as e:
        print(f"Invalid JSON: {e}", file=sys.stderr)
        return 1

    if not args.readme_path.exists():
        print(f"README not found: {args.readme_path}", file=sys.stderr)
        return 1

    changed = update_readme(args.readme_path, top_repos, new_repos, args.dry_run)
    return 0 if changed or args.dry_run else 0


if __name__ == "__main__":
    sys.exit(main())
