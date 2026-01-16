# Security Policy

## Reporting a Vulnerability

The zircote organization takes security seriously. We appreciate responsible disclosure of security vulnerabilities.

### How to Report

**Email**: security@zircote.com

Please include:
- Type of vulnerability
- Location of affected source code (file path, tag/branch/commit)
- Steps to reproduce
- Proof-of-concept if available
- Potential impact assessment

### What to Expect

1. **Acknowledgment**: Within 48 hours
2. **Assessment**: Validity and severity determination within 7 days
3. **Resolution**: Fix development and coordinated disclosure
4. **Credit**: Recognition in release notes (with permission)

### Scope

**In Scope**:
- Source code in zircote repositories
- Configuration and infrastructure code
- Authentication and authorization
- Data handling and API endpoints

**Out of Scope**:
- Social engineering
- Physical security
- Denial of service
- Third-party services
- Already reported issues

### Disclosure Policy

- Allow 90 days for remediation before public disclosure
- Coordinate disclosure timing
- Security advisories via GitHub Security Advisories

### Safe Harbor

Security research conducted under this policy is:
- Authorized under applicable laws
- Protected from legal action for good-faith violations
- Valued as contribution to security

Please:
- Avoid privacy violations and data destruction
- Only test accounts you own or have permission for
- Stop and report immediately upon encountering sensitive data

## Supported Versions

- Latest major version
- Previous major version (6 months after new major release)

See individual repositories for specific policies.

## Security Best Practices

- Never commit secrets or credentials
- Use environment variables for sensitive data
- Follow least privilege principles
- Keep dependencies updated
- Validate all user inputs
- Use parameterized queries

## Changelog

| Date | Change |
|------|--------|
| 2026-01-16 | Added changelog section |
| 2025-12-20 | Initial release with vulnerability reporting and security best practices |
