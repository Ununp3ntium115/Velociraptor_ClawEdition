# macOS SDLC Agent System

## Quick Reference

This directory contains the complete HiQ Agent Swarm system for Velociraptor Claw Edition (macOS).

## Files

```
.claude/agents/
├── MACOS_SDLC_AGENT_PROMPTS.md    # All 9 agent system prompts
├── README.md                       # This file
├── mcp/
│   └── agent-configs.yaml          # MCP-ready agent configurations
└── scripts/
    ├── run-gap-analysis.sh         # Gap analysis execution script
    └── fix-all-gaps-iterative.sh   # Iterative gap closure orchestrator
```

## Agent Summary

| # | Agent | Role | Input → Output |
|---|-------|------|----------------|
| 0 | Stage Authority | Context charter | N/A (shared context) |
| 1 | Development | Swift implementation | Gap → Code |
| 2 | Testing | Xcode test execution | Code → Test Results |
| 3 | QA | Quality validation | Tests → Quality Verdict |
| 4 | UAT | Workflow validation | Quality → User Verdict |
| 5 | Platform QA | Apple compliance | User → Platform Verdict |
| 6 | Security | Security validation | Platform → Security Verdict |
| 7 | Gap Analysis | Gap discovery | Repo → Gap Registry |
| 8 | Orchestrator | Swarm conductor | Registry → Closed Gaps |
| 9 | Foreman | Unified meta-agent | Requirements → Production |

## Quick Start

### 1. Run Gap Analysis

```bash
cd /Users/brodynielsen/GitRepos/Velociraptor_ClawEdition
./.claude/agents/scripts/run-gap-analysis.sh
```

### 2. Run Iterative Gap Closure

```bash
# MVP scope (P0 gaps only)
SCOPE=mvp ./.claude/agents/scripts/fix-all-gaps-iterative.sh

# Full scope (all gaps)
SCOPE=full ./.claude/agents/scripts/fix-all-gaps-iterative.sh
```

### 3. Use Agent Prompts

Copy the relevant prompt from `MACOS_SDLC_AGENT_PROMPTS.md` and use it as a system prompt for your HiQ agent or Claude session.

## SDLC Flow

```
Gap Analysis → Master Iteration Document → Agent Dispatch
    ↓
Development (Swift 6 / SwiftUI / AppKit)
    ↓ "Implemented – Pending Test"
Testing (Xcode tests, determinism check)
    ↓ "Tested – Pending QA"
QA (Regression, performance, UI consistency)
    ↓ "QA-Validated – Pending UAT"
UAT (Real-world workflow validation)
    ↓ "UAT-Approved – Pending Platform QA"
macOS Platform QA (Accessibility, HIG, SDK)
    ↓ "Platform-Validated – Pending Security"
Security (Sandbox, hardened runtime, notarization)
    ↓ "Production-Eligible"
    
Re-run Gap Analysis → Repeat until convergence
```

## Key Concepts

### CDIF/CEDIF (read structure first)
CryptEx Intelligence Document Framework - canonical patterns and implementations.
- **Location**: `apps/macos-legacy/CDIF_TEST_ARCHETYPES.md`
- **Read first**: Open that file and read the **CDIF Structure (read first)** section. It defines the document layout, test archetypes (FC-*, MAC-*), parent/child registry (in `MACOS_SDLC_AGENT_PROMPTS.md`), and path resolution. Use the **Path Reference Index** in the catalog and `docs/WORKSPACE_PATH_INDEX.md` for all canonical paths.
- **KB entrypoint**: `steering/CDIF_KB_INDEX.md` (curated index + exclusions like `tests/results/` and `node_modules/`)

### Gap Registry
Authoritative list of gaps with hexadecimal IDs.
- Location: `Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md`

### Master Iteration Document
Line-by-line task breakdown for the current iteration.
- Location: `Velociraptor_macOS_App/steering/MACOS-IMPLEMENTATION-GUIDE.md`

### MCP Integration
Model Context Protocol for task orchestration.
- Config: `.claude/agents/mcp/agent-configs.yaml`

## Current Gap Status (2026-01-31)

| Gap | Title | Priority | Status |
|-----|-------|----------|--------|
| 0x01 | Velociraptor API Client | P0 | 🔴 OPEN |
| 0x02 | Client Management Interface | P0 | 🔴 OPEN |
| 0x03 | Hunt Management Interface | P0 | 🔴 OPEN |
| 0x04 | VQL Terminal | P0 | 🔴 OPEN |
| 0x05 | Dashboard with Widgets | P0 | 🔴 OPEN |
| 0x06 | VFS Browser | P1 | 🔴 OPEN |
| 0x07 | DFIR Tools Integration | P1 | 🔴 OPEN |
| 0x08 | WebSocket Real-Time | P1 | 🔴 OPEN |
| 0x09 | Accessibility Identifiers | P0 | 🔴 OPEN |

## MVP Scope

To reach MVP (functional DFIR platform), close these 6 P0 gaps:
- 0x01: API Client (blocks everything)
- 0x02: Client Management
- 0x03: Hunt Management
- 0x04: VQL Terminal
- 0x05: Dashboard
- 0x09: Accessibility

**Estimated Effort**: 116-142 hours

## Repository Structure

```
apps/macos-legacy/
├── VelociraptorMacOS/
│   ├── Models/          # Data models
│   ├── Views/           # SwiftUI views
│   │   └── Steps/       # Wizard step views
│   ├── Services/        # Business logic
│   ├── Utilities/       # Helpers
│   └── TestingAgent/    # Built-in test framework
├── VelociraptorMacOSTests/      # Unit tests
└── VelociraptorMacOSUITests/    # UI tests
```

## Convergence Criteria

### MVP
- P0 gaps = 0
- P1 gaps = 0 (or accepted)
- Security gate = PASS
- Notarization = READY

### Full Parity
- All gaps (0x01-0x12) = CLOSED
- Full Electron feature parity
