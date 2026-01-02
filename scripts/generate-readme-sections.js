#!/usr/bin/env node
/**
 * Generate README sections from analyzed GitHub activity data.
 *
 * This script takes activity data from environment variables and generates
 * formatted markdown sections suitable for a GitHub profile README.
 *
 * Environment Variables:
 *   TOP_REPOS - JSON array of top repositories
 *   NEW_REPOS - JSON array of new repositories
 *   ACTIVITY_SUMMARY - JSON object with analysis summary
 */

const fs = require('fs');

/**
 * Get activity emoji based on score
 * @param {number} score - Repository activity score (0-1)
 * @returns {string} Emoji indicator
 */
function getActivityEmoji(score) {
  if (score >= 0.7) return '🔥';
  if (score >= 0.4) return '✨';
  if (score >= 0.2) return '📈';
  return '💤';
}

/**
 * Truncate text to max length with ellipsis
 * @param {string} text - Text to truncate
 * @param {number} maxLength - Maximum length
 * @returns {string} Truncated text
 */
function truncate(text, maxLength) {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength - 3) + '...';
}

/**
 * Generate markdown for top repositories section
 * @param {Array} repos - Array of repository objects
 * @returns {string} Markdown table
 */
function generateTopReposMarkdown(repos) {
  if (!repos || repos.length === 0) {
    return '*No active repositories found.*';
  }

  const header = `| Repository | Description | Tech | Activity |
|------------|-------------|------|----------|`;

  const rows = repos.map(repo => {
    const name = repo.name;
    const url = repo.url;
    const desc = truncate(repo.description || 'No description', 55).replace(/\|/g, '\\|');
    const lang = repo.language || 'Mixed';
    const emoji = getActivityEmoji(repo.score);

    return `| [${name}](${url}) | ${desc} | ${lang} | ${emoji} |`;
  });

  return [header, ...rows].join('\n');
}

/**
 * Generate markdown for new repositories section
 * @param {Array} repos - Array of repository objects
 * @returns {string} Markdown list
 */
function generateNewReposMarkdown(repos) {
  if (!repos || repos.length === 0) {
    return '*No new repositories in the last 90 days.*';
  }

  return repos.map(repo => {
    const name = repo.name;
    const url = repo.url;
    const desc = truncate(repo.description || 'No description', 70);
    const lang = repo.language || 'Mixed';

    return `- **[${name}](${url})** (${lang}) - ${desc}`;
  }).join('\n');
}

/**
 * Main execution
 */
function main() {
  try {
    // Parse environment variables
    const topRepos = JSON.parse(process.env.TOP_REPOS || '[]');
    const newRepos = JSON.parse(process.env.NEW_REPOS || '[]');

    // Generate markdown sections
    const topReposMarkdown = generateTopReposMarkdown(topRepos);
    const newReposMarkdown = generateNewReposMarkdown(newRepos);

    // Output for logging
    console.log('=== Generated Top Repos Section ===');
    console.log(topReposMarkdown);
    console.log('\n=== Generated New Repos Section ===');
    console.log(newReposMarkdown);

    // Write to GitHub output if available
    const outputFile = process.env.GITHUB_OUTPUT;
    if (outputFile) {
      const content = `content<<EOF
{
  "top_repos_markdown": ${JSON.stringify(topReposMarkdown)},
  "new_repos_markdown": ${JSON.stringify(newReposMarkdown)},
  "generated_at": "${new Date().toISOString()}"
}
EOF
`;
      fs.appendFileSync(outputFile, content);
      console.log('\nWritten to GITHUB_OUTPUT');
    }

    // Also write to temp files for debugging
    fs.writeFileSync('/tmp/top-repos.md', topReposMarkdown);
    fs.writeFileSync('/tmp/new-repos.md', newReposMarkdown);

  } catch (error) {
    console.error('Error generating README sections:', error.message);
    process.exit(1);
  }
}

main();
