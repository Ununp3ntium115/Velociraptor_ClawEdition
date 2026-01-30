# GitHub Agents Directory

This directory contains system prompts and documentation for specialized agents that work on different aspects of the Velociraptor Claw Edition project.

## Purpose

Agent documentation provides:
- **Role Definition**: What the agent is responsible for
- **Context**: Product, toolchain, and technical constraints
- **Rules**: Platform-specific requirements and best practices
- **Workflows**: Step-by-step processes for common tasks
- **Patterns**: Code templates and examples
- **Quality Standards**: Testing, accessibility, and documentation requirements

## Available Agents

### 1. macOS Development Agent
**File**: `macos-development-agent.md`  
**Role**: Swift 6 / SwiftUI / AppKit implementation for macOS native application  
**Scope**: VelociraptorMacOS Swift package

**Key Responsibilities**:
- Implement gaps from Master Iteration Document
- Follow Swift 6 concurrency rules (@MainActor, async/await, Sendable)
- Maintain Xcode project structure via XcodeGen
- Apply accessibility identifiers for UI testing
- Respect App Sandbox entitlements
- Integrate with macOS system services (Keychain, launchd, UserNotifications)

**When to Use**:
- Adding new Swift code to VelociraptorMacOS
- Modifying existing macOS UI components
- Implementing macOS-specific features
- Writing tests for macOS application

## Agent Conventions

All agent documentation follows this structure:

1. **Agent Purpose** - What the agent does
2. **Implementation Context** - Product, toolchain, capabilities
3. **Platform Rules** - Must-follow requirements
4. **Workflow** - Step-by-step implementation process
5. **Outputs** - Expected deliverables format
6. **Quick Reference** - Commands, files, patterns

## Adding New Agents

When creating a new agent:

1. Create a new `.md` file in this directory
2. Follow the structure of existing agents
3. Include concrete examples and code patterns
4. Specify output format for gap implementations
5. Document integration points with other systems
6. Update this README with agent details

## Integration with HiQ Swarm

These agents are designed to work in a HiQ (High Intelligence Quotient) swarm architecture:

- **Circular Iteration**: Plan → Build → Test → Review → Plan
- **Gap-Based Development**: One gap at a time from iteration documents
- **State Tracking**: Clear gap states (Planning, Implementing, Testing, Complete)
- **Documentation First**: Gaps defined before implementation
- **Quality Gates**: Testing and review before marking complete

## Related Documentation

- **Iteration Plans**: `steering/MACOS_MASTER_ITERATION_PLAN.md`
- **Gap Analysis**: `steering/MACOS_GAP_ANALYSIS_ITERATION_2.md`
- **Production Status**: `steering/MACOS_PRODUCTION_COMPLETE.md`
- **Contributing Guide**: `docs/MACOS_CONTRIBUTING.md`

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-30 | Initial agents directory with macOS Development Agent |

---

*This directory is part of the Velociraptor Claw Edition development infrastructure.*
