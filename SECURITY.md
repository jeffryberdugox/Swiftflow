# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

The SwiftFlow team takes security bugs seriously. We appreciate your efforts to responsibly disclose your findings, and will make every effort to acknowledge your contributions.

### How to Report a Security Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

1. **Preferred**: Open a [Security Advisory](https://github.com/jeffryberdugox/SwiftFlow/security/advisories/new) on GitHub
2. **Alternative**: Send an email to [jeffryberdugo19942@gmail.com](mailto:jeffryberdugo19942@gmail.com)

Please include the following information:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response Timeline

- **Initial Response**: Within 48 hours, we will acknowledge receipt of your vulnerability report
- **Status Update**: Within 7 days, we will provide a detailed response with our evaluation and expected timeline
- **Fix Release**: We aim to release a fix within 30 days for critical vulnerabilities

### What to Expect

After you submit a report, we will:

1. Confirm the problem and determine affected versions
2. Audit code to find any similar problems
3. Prepare fixes for all supported releases
4. Release new versions as soon as possible
5. Credit you for the discovery (unless you prefer to remain anonymous)

## Security Best Practices for Users

When using SwiftFlow in your projects:

1. **Keep Updated**: Always use the latest stable version
2. **Validate Input**: Sanitize any user input before creating nodes or edges
3. **Access Control**: Implement proper access control if exposing node editing to users
4. **Code Review**: Review any custom node implementations for security issues
5. **Dependencies**: While SwiftFlow has zero dependencies, keep your project dependencies updated

## Scope

The following are considered in scope for security reports:

- Remote code execution
- Denial of service attacks
- Information disclosure
- Authentication/authorization bypass
- Injection vulnerabilities (if accepting external data)

The following are considered out of scope:

- Vulnerabilities in example code or documentation
- Vulnerabilities requiring physical access to a user's device
- Social engineering attacks
- Issues in third-party libraries (report to those projects directly)

## Public Disclosure

We follow a coordinated disclosure process:

1. Security issues are kept confidential until a fix is released
2. Once a fix is available, we will:
   - Release the patched version
   - Publish a security advisory
   - Credit the reporter (if they agree)
   - Update this document if necessary

## Bug Bounty Program

Currently, SwiftFlow does not have a bug bounty program. However, we deeply appreciate security researchers who report vulnerabilities responsibly and will publicly acknowledge their contributions.

## Contact

For any questions about security, please contact:
- **GitHub Security**: [Security Advisories](https://github.com/jeffryberdugox/SwiftFlow/security/advisories)
- **Email**: jeffryberdugo19942@gmail.com

## Recognition

We believe in recognizing security researchers for their valuable contributions. If you've reported a security issue that we've fixed, we'll:

- List you in our security acknowledgments (with your permission)
- Mention you in the release notes
- Provide a letter of appreciation for your portfolio (upon request)

---

Thank you for helping keep SwiftFlow and its users safe!
