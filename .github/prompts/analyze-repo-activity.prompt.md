---
mode: "agent"
description: "Deep analysis of repository activity for profile highlights"
tools: ["shell", "codebase"]
---

# Analyze Repository Activity

Perform deep analysis of a GitHub user's repository activity to identify the most significant and active projects.

## Context

This prompt helps analyze which repositories should be highlighted in a profile README based on actual contribution patterns, community engagement, and project significance.

## Analysis Dimensions

### 1. Contribution Velocity
```bash
# Recent commit activity (last 90 days)
gh api repos/{{owner}}/{{repo}}/commits \
  --paginate \
  -q '[.[] | select(.commit.author.date > "{{cutoff_date}}")] | length'
```

### 2. Community Engagement
```bash
# Stars and forks
gh api repos/{{owner}}/{{repo}} \
  -q '{stars: .stargazers_count, forks: .forks_count, watchers: .watchers_count}'

# Recent issues and PRs
gh api repos/{{owner}}/{{repo}}/issues \
  -q '[.[] | select(.created_at > "{{cutoff_date}}")] | length'
```

### 3. Project Health Signals
```bash
# Check for recent releases
gh api repos/{{owner}}/{{repo}}/releases \
  -q '.[0] | {tag: .tag_name, date: .published_at}'

# Dependency updates (if dependabot)
gh api repos/{{owner}}/{{repo}}/pulls \
  -q '[.[] | select(.user.login == "dependabot[bot]" and .state == "open")] | length'
```

### 4. Documentation Quality
- Has README.md with substantial content
- Has CONTRIBUTING.md
- Has CODE_OF_CONDUCT.md
- Has LICENSE

## Scoring Formula

```python
score = (
    (commits_90d / 50) * 0.40 +           # Commit activity
    (stars / 1000) * 0.20 +                # Community validation
    (forks / 100) * 0.15 +                 # Fork engagement
    ((issues + prs) / 20) * 0.15 +         # Issue/PR activity
    (pushes_30d / 10) * 0.10               # Recent activity
) + recency_bonus
```

Where `recency_bonus = max(0, 1 - days_since_update/90) * 0.2`

## Output

Generate a ranked list with:
1. Repository name and URL
2. Primary language
3. Short description (max 60 chars)
4. Activity score (0-1)
5. Activity indicator emoji
6. Key metrics (stars, forks, recent commits)

## Usage Example

```
Analyze zircote's repositories and identify the top 8 most significant active projects,
excluding forks and archived repositories. Output should be suitable for profile README.
```
