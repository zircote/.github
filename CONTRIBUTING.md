# Contributing to .github

Thank you for your interest in contributing to .github! This document provides guidelines and information for contributors.

## How to Contribute

### Reporting Bugs

1. **Search existing issues** at [github.com/zircote/.github/issues](https://github.com/zircote/.github/issues) to avoid duplicates.
2. If no existing issue matches, [open a new bug report](https://github.com/zircote/.github/issues/new?template=bug_report.yml).
3. Include as much detail as possible: steps to reproduce, expected vs actual behavior, environment details, and logs or screenshots.

### Suggesting Features

1. **Check discussions and issues** to see if the feature has already been proposed.
2. [Open a feature request](https://github.com/zircote/.github/issues/new?template=feature_request.yml) with a clear description of the problem and your proposed solution.

### Submitting Pull Requests

1. **Fork the repository** and create a branch from `main`.
2. **Make your changes** in a focused, well-scoped branch.
3. **Write or update tests** to cover your changes.
4. **Update documentation** if your changes affect public APIs or user-facing behavior.
5. **Open a pull request** against `main` using the PR template.

## Development Setup

1. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/.github.git
   cd .github
   ```
2. Install dependencies (see README for project-specific instructions).
3. Run the test suite to verify your setup.

## Code Style

- Follow the existing code style and conventions in the project.
- Run linters and formatters before committing.
- Keep changes focused: one logical change per commit.

## Commit Messages

Use clear, descriptive commit messages:

```
<type>: <short summary>

<optional body with more detail>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`

Examples:
- `feat: add user profile page`
- `fix: correct date parsing for ISO 8601 format`
- `docs: update API reference for v2 endpoints`

## Pull Request Process

1. Fill out the PR template completely.
2. Link related issues using `Fixes #123` or `Closes #456`.
3. Ensure all CI checks pass.
4. Request a review from a maintainer or code owner.
5. Address review feedback promptly.
6. Once approved, a maintainer will merge your PR.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Report unacceptable behavior to the project maintainers.

## Questions?

- Open a [discussion](https://github.com/zircote/.github/discussions) for general questions.
- Check the [support document](SUPPORT.md) for additional resources.
