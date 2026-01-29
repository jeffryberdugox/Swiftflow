# SwiftFlow Governance

## Project Leadership

**Maintainer**: Jeffry Berdugo (@jeffryberdugox)

## Decision Making

For this early stage of the project:
- Major architectural decisions are made by the maintainer
- Community feedback is welcomed through GitHub Issues and Discussions
- Feature requests are evaluated based on:
  - Alignment with project goals
  - Implementation complexity
  - Community demand
  - Maintenance burden

## Contribution Process

### 1. **For Bug Fixes**
- Open an issue describing the bug
- Submit a PR with the fix
- PR must pass all CI checks
- Maintainer will review and merge

### 2. **For New Features**
- Open a Discussion or Issue proposing the feature
- Wait for feedback/approval before starting work
- Submit a PR once approved
- PR must pass all CI checks and code review

### 3. **For Documentation**
- PRs are welcome directly
- Must follow existing style and format
- CI checks must pass

## Code Review Process

All code changes require:
1. ✅ All CI checks passing (build, tests, linting)
2. ✅ Code review approval from maintainer
3. ✅ Documentation updates (if applicable)
4. ✅ Tests for new features
5. ✅ Following the Swift style guide

## Branch Protection

The `main` branch is protected:
- Direct pushes are not allowed
- All changes must come through Pull Requests
- CI checks must pass
- Code review approval required

## Commit Rights

### Contributors (Default)
- Can fork and create PRs
- Can comment on issues/PRs
- No direct commit access

### Collaborators (By Invitation)
- Can create branches in the main repo
- Can create PRs
- Still require review for merging

### Maintainers
- @jeffryberdugox
- Can approve and merge PRs
- Can create releases
- Can modify project settings

## Release Process

Releases are managed by the maintainer:
1. Version is bumped following SemVer
2. CHANGELOG.md is updated
3. Git tag is created
4. GitHub Release is published
5. Documentation is deployed

## Community Standards

We follow:
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)

## Future Evolution

As the project grows, this governance model may evolve to include:
- Multiple maintainers
- Working groups for specific areas
- More formal RFC process for major changes
- Community voting on features

## Contact

- **Issues**: For bugs and feature requests
- **Discussions**: For questions and ideas
- **Email**: jeffryberdugo19942@gmail.com
- **Twitter**: @jeffryberdugo

---

Last updated: January 2026
