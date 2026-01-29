# Contributing to SwiftFlow

First off, thank you for considering contributing to SwiftFlow! It's people like you that make SwiftFlow such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by the [SwiftFlow Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details as possible.
* **Provide specific examples to demonstrate the steps**. Include links to files or GitHub projects, or copy/pasteable snippets, which you use in those examples.
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
* **Explain which behavior you expected to see instead and why.**
* **Include screenshots or animated GIFs** which show you following the described steps and clearly demonstrate the problem.
* **Include your Swift version, macOS version, and Xcode version.**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title** for the issue to identify the suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
* **Provide specific examples to demonstrate the steps** or provide mockups/wireframes if applicable.
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
* **Explain why this enhancement would be useful** to most SwiftFlow users.

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Include screenshots and animated GIFs in your pull request whenever possible
* Follow the Swift style guide
* Include tests when adding new features
* Update documentation when changing public APIs
* End all files with a newline

## Development Process

### Setting Up Your Development Environment

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/SwiftFlow.git
   cd SwiftFlow
   ```
3. Create a branch:
   ```bash
   git checkout -b feature/my-new-feature
   ```

### Building and Testing

#### Build the Package

```bash
swift build
```

#### Run Tests

```bash
swift test
```

#### Open in Xcode

```bash
open Package.swift
```

### Code Style Guidelines

* **Language**: All code comments and documentation must be in **English**
* **Documentation**: Use Swift's documentation comments (`///`) for all public APIs
* **Naming**: Follow Apple's [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
* **Formatting**: Use 4 spaces for indentation, not tabs
* **Line Length**: Aim for 120 characters maximum
* **Access Control**: Be explicit with access control (`public`, `internal`, `private`)
* **Comments**: Write clear, concise comments explaining the "why", not the "what"

### Architecture Guidelines

SwiftFlow follows a three-layer architecture:

1. **Core Layer** (Pure Swift, no SwiftUI)
   - Protocols, types, commands, math utilities
   - Must remain framework-agnostic

2. **Engine Layer** (Business Logic)
   - Controllers, managers, caches
   - Handles state management and interactions

3. **View Layer** (SwiftUI)
   - Views, modifiers, and UI components
   - Only this layer should import SwiftUI

When contributing:
- Keep concerns separated across layers
- Avoid circular dependencies
- Maintain backward compatibility when possible

### Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

Example:
```
Add support for custom edge markers

- Implement MarkerType enum with arrow, dot, and custom options
- Add markerStart and markerEnd configuration to EdgeConfig
- Update EdgeView to render markers at endpoints
- Add tests for marker positioning

Closes #123
```

### Testing Guidelines

* Write unit tests for all new functionality
* Ensure all tests pass before submitting a PR
* Aim for meaningful test coverage, not just high percentages
* Test edge cases and error conditions
* Use descriptive test names that explain what is being tested

Example:
```swift
func testNodeMovementWithSnapToGrid() {
    // Test that nodes snap to grid when enabled
}
```

### Documentation Guidelines

* Document all public APIs with `///` comments
* Include code examples in documentation when helpful
* Update relevant markdown files in `Documentation/` folder
* Keep `CHANGELOG.md` updated with your changes
* Update `README.md` if adding major features

## Project Structure

```
SwiftFlow/
├── Sources/
│   └── SwiftFlow/
│       ├── Controller/        # Canvas controller and advanced access
│       ├── Core/              # Core types, protocols, commands
│       ├── Managers/          # Interaction managers
│       ├── Protocols/         # FlowNode, FlowEdge, FlowPort
│       ├── Utils/             # Helper functions
│       ├── Views/             # SwiftUI views and modifiers
│       └── SwiftFlow.docc/    # Swift-DocC documentation
├── Tests/
│   └── SwiftFlowTests/        # Unit and integration tests
├── Documentation/              # Additional markdown guides
└── Package.swift              # Swift Package manifest
```

## Release Process

Maintainers follow this process for releases:

1. Update version in appropriate files
2. Update `CHANGELOG.md` with release notes
3. Create a git tag with version number
4. Create a GitHub release with changelog
5. Announce on relevant channels

## Questions?

Don't hesitate to ask questions by opening an issue with the "question" label. We're here to help!

## Attribution

This contributing guide is adapted from the open source contribution guidelines for [Atom](https://github.com/atom/atom/blob/master/CONTRIBUTING.md).

---

Thank you for contributing to SwiftFlow! 🎉
