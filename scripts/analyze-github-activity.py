#!/usr/bin/env python3
"""
Analyze GitHub public activity for profile README generation.

Fetches user's public repositories and events to calculate:
- Top N most significant active repos (weighted scoring)
- Recently created repositories

Weighting factors:
- Commits in last 90 days (40%)
- Stars (20%)
- Forks (15%)
- Issues/PRs activity (15%)
- Recent pushes (10%)
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any

import requests
from dateutil.parser import parse as parse_date


@dataclass
class RepoScore:
    """Repository with calculated significance score."""

    name: str
    full_name: str
    description: str | None
    url: str
    language: str | None
    stars: int
    forks: int
    open_issues: int
    created_at: datetime
    updated_at: datetime
    pushed_at: datetime
    is_fork: bool
    topics: list[str] = field(default_factory=list)

    # Activity metrics
    recent_commits: int = 0
    recent_issues: int = 0
    recent_prs: int = 0
    recent_pushes: int = 0

    # Calculated score
    score: float = 0.0

    def calculate_score(self, now: datetime) -> float:
        """Calculate weighted significance score."""
        # Normalize metrics (0-1 scale with caps)
        commit_score = min(self.recent_commits / 50, 1.0)  # Cap at 50 commits
        star_score = min(self.stars / 1000, 1.0)  # Cap at 1000 stars
        fork_score = min(self.forks / 100, 1.0)  # Cap at 100 forks
        activity_score = min((self.recent_issues + self.recent_prs) / 20, 1.0)
        push_score = min(self.recent_pushes / 10, 1.0)

        # Recency bonus (repos updated in last 30 days get a boost)
        days_since_update = (now - self.updated_at).days
        recency_bonus = max(0, 1 - (days_since_update / 90)) * 0.2

        # Apply weights
        self.score = (
            commit_score * 0.40
            + star_score * 0.20
            + fork_score * 0.15
            + activity_score * 0.15
            + push_score * 0.10
            + recency_bonus
        )

        return self.score

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for JSON output."""
        return {
            "name": self.name,
            "full_name": self.full_name,
            "description": self.description or "",
            "url": self.url,
            "language": self.language or "Unknown",
            "stars": self.stars,
            "forks": self.forks,
            "topics": self.topics,
            "score": round(self.score, 4),
            "recent_commits": self.recent_commits,
            "days_since_update": (datetime.now(timezone.utc) - self.updated_at).days,
        }


class GitHubActivityAnalyzer:
    """Analyze GitHub user activity."""

    API_BASE = "https://api.github.com"

    def __init__(self, token: str | None = None) -> None:
        self.session = requests.Session()
        self.session.headers.update({
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        })
        if token:
            self.session.headers["Authorization"] = f"Bearer {token}"

    def get_user_repos(self, username: str) -> list[dict[str, Any]]:
        """Fetch all public repositories for a user."""
        repos: list[dict[str, Any]] = []
        page = 1
        per_page = 100

        while True:
            response = self.session.get(
                f"{self.API_BASE}/users/{username}/repos",
                params={
                    "type": "owner",  # Only repos owned by user
                    "sort": "updated",
                    "direction": "desc",
                    "per_page": per_page,
                    "page": page,
                },
            )
            response.raise_for_status()
            data = response.json()

            if not data:
                break

            repos.extend(data)
            page += 1

            # Safety limit
            if page > 10:
                break

        return repos

    def get_user_events(
        self, username: str, days: int = 90
    ) -> list[dict[str, Any]]:
        """Fetch recent public events for a user."""
        events: list[dict[str, Any]] = []
        cutoff = datetime.now(timezone.utc) - timedelta(days=days)
        page = 1

        # GitHub events API: max 300 events (3 pages of 100)
        while page <= 3:
            try:
                response = self.session.get(
                    f"{self.API_BASE}/users/{username}/events/public",
                    params={"per_page": 100, "page": page},
                )
                response.raise_for_status()
                data = response.json()

                if not data:
                    break

                for event in data:
                    event_time = parse_date(event["created_at"])
                    if event_time < cutoff:
                        return events
                    events.append(event)

                page += 1
            except requests.HTTPError as e:
                # Events API often returns 422 on later pages
                if e.response.status_code == 422:
                    break
                raise

        return events

    def analyze_repos(
        self, username: str, top_count: int = 8, new_days: int = 90
    ) -> tuple[list[RepoScore], list[RepoScore]]:
        """
        Analyze repositories and return top active and new repos.

        Returns:
            Tuple of (top_repos, new_repos)
        """
        now = datetime.now(timezone.utc)
        cutoff_new = now - timedelta(days=new_days)

        # Fetch data
        raw_repos = self.get_user_repos(username)
        events = self.get_user_events(username)

        # Build repo objects
        repos: dict[str, RepoScore] = {}
        new_repos: list[RepoScore] = []

        for repo_data in raw_repos:
            # Skip forks for top repos ranking
            if repo_data.get("fork"):
                continue

            # Skip archived repos
            if repo_data.get("archived"):
                continue

            created = parse_date(repo_data["created_at"])
            updated = parse_date(repo_data["updated_at"])
            pushed = parse_date(repo_data["pushed_at"]) if repo_data.get("pushed_at") else updated

            repo = RepoScore(
                name=repo_data["name"],
                full_name=repo_data["full_name"],
                description=repo_data.get("description"),
                url=repo_data["html_url"],
                language=repo_data.get("language"),
                stars=repo_data.get("stargazers_count", 0),
                forks=repo_data.get("forks_count", 0),
                open_issues=repo_data.get("open_issues_count", 0),
                created_at=created,
                updated_at=updated,
                pushed_at=pushed,
                is_fork=repo_data.get("fork", False),
                topics=repo_data.get("topics", []),
            )

            repos[repo.full_name] = repo

            # Track new repos
            if created > cutoff_new:
                new_repos.append(repo)

        # Process events to count activity
        for event in events:
            repo_name = event.get("repo", {}).get("name")
            if not repo_name or repo_name not in repos:
                continue

            repo = repos[repo_name]
            event_type = event.get("type")

            if event_type == "PushEvent":
                commits = event.get("payload", {}).get("commits", [])
                repo.recent_commits += len(commits)
                repo.recent_pushes += 1
            elif event_type == "IssuesEvent":
                repo.recent_issues += 1
            elif event_type == "PullRequestEvent":
                repo.recent_prs += 1

        # Calculate scores and sort
        for repo in repos.values():
            repo.calculate_score(now)

        top_repos = sorted(repos.values(), key=lambda r: r.score, reverse=True)[
            :top_count
        ]

        # Sort new repos by creation date
        new_repos = sorted(new_repos, key=lambda r: r.created_at, reverse=True)[:5]

        return top_repos, new_repos


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Analyze GitHub activity for profile README"
    )
    parser.add_argument("--user", required=True, help="GitHub username")
    parser.add_argument(
        "--top-count", type=int, default=8, help="Number of top repos to return"
    )
    parser.add_argument(
        "--new-days", type=int, default=90, help="Days to consider for new repos"
    )
    parser.add_argument(
        "--output-format",
        choices=["json", "github-output"],
        default="json",
        help="Output format",
    )
    args = parser.parse_args()

    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")

    try:
        analyzer = GitHubActivityAnalyzer(token)
        top_repos, new_repos = analyzer.analyze_repos(
            args.user, args.top_count, args.new_days
        )

        top_repos_data = [r.to_dict() for r in top_repos]
        new_repos_data = [r.to_dict() for r in new_repos]

        summary = {
            "analyzed_at": datetime.now(timezone.utc).isoformat(),
            "user": args.user,
            "top_repos_count": len(top_repos_data),
            "new_repos_count": len(new_repos_data),
        }

        if args.output_format == "github-output":
            # Write to GitHub Actions output
            output_file = os.environ.get("GITHUB_OUTPUT")
            if output_file:
                with open(output_file, "a") as f:
                    # Use heredoc for multiline JSON
                    f.write(f"top_repos<<EOF\n{json.dumps(top_repos_data)}\nEOF\n")
                    f.write(f"new_repos<<EOF\n{json.dumps(new_repos_data)}\nEOF\n")
                    f.write(f"summary<<EOF\n{json.dumps(summary)}\nEOF\n")
            else:
                print("Warning: GITHUB_OUTPUT not set", file=sys.stderr)
                print(json.dumps({"top_repos": top_repos_data, "new_repos": new_repos_data}, indent=2))
        else:
            output = {
                "top_repos": top_repos_data,
                "new_repos": new_repos_data,
                "summary": summary,
            }
            print(json.dumps(output, indent=2))

        return 0

    except requests.HTTPError as e:
        print(f"GitHub API error: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
