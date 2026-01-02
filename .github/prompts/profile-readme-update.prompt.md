---
mode: "agent"
description: "Update profile README with GitHub activity analysis"
tools: ["codebase", "shell"]
---

# Update Profile README

Analyze the user's public GitHub activity and update the profile README with current activity highlights.

## Task Overview

You are updating the organization profile README located at `profile/README.md` with:
1. **Top 8 Most Active Repositories** - Ranked by a weighted scoring algorithm
2. **New Repositories** - Recently created repos in the last 90 days

## Weighting Algorithm

Calculate repository significance using these weights:
- **Recent commits (40%)** - Commits in the last 90 days
- **Stars (20%)** - Stargazer count
- **Forks (15%)** - Fork count
- **Issue/PR activity (15%)** - Recent issues and pull requests
- **Push recency (10%)** - How recently the repo was pushed to

## Data Collection

### Step 1: Fetch Repository Data
```bash
# Get user's public repos sorted by activity
gh api users/zircote/repos \
  --paginate \
  -q '.[] | select(.fork == false and .archived == false) | {name, description, language, stargazers_count, forks_count, updated_at, pushed_at, html_url, topics}'
```

### Step 2: Fetch Recent Events
```bash
# Get recent public activity (last 90 days)
gh api users/zircote/events/public --paginate -q '.[].type' | sort | uniq -c
```

### Step 3: Count Commits by Repo
```bash
# For each significant repo, count recent commits
gh api repos/zircote/{REPO}/commits \
  --paginate \
  -q 'length'
```

## Output Format

### Active Repositories Section

Generate a markdown table between the markers:
```markdown
<!-- ACTIVE_REPOS_START -->
| Repository | Description | Tech | Activity |
|------------|-------------|------|----------|
| [repo-name](url) | Description... | Language | 🔥 Very Active |
<!-- ACTIVE_REPOS_END -->
```

Activity indicators:
- 🔥 Very Active (score >= 0.7)
- ✨ Active (score >= 0.4)
- 📈 Growing (score >= 0.2)
- 💤 Stable (score < 0.2)

### New Repositories Section

Generate a markdown list between the markers:
```markdown
<!-- NEW_REPOS_START -->
- **[repo-name](url)** (Language) - Description
<!-- NEW_REPOS_END -->
```

### Timestamp

Update the last updated marker:
```markdown
<!-- LAST_UPDATED_START --> _Last updated: YYYY-MM-DD_ <!-- LAST_UPDATED_END -->
```

## Validation Checklist

Before completing:
- [ ] All repository links are valid
- [ ] Descriptions are properly escaped (no broken markdown)
- [ ] Activity scores reflect actual recent activity
- [ ] New repos section only contains repos < 90 days old
- [ ] Table formatting is correct

## Execution

1. Run the analysis script: `python scripts/analyze-github-activity.py --user zircote --top-count 8`
2. Review the generated data for accuracy
3. Update `profile/README.md` with the new sections
4. Verify markdown renders correctly
