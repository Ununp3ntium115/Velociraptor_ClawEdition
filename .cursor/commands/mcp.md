# MCP Server Management & Canonical Path Runbook
## Velociraptor Claw Edition

**Purpose**: Manage the Velociraptor Claw Edition DFIR MCP server and enforce canonical path rules across all agent/AI interactions.

**Last Updated**: 2026-02-04

---

## Terminology

| Term | Meaning |
|------|---------|
| **Velociraptor** | The official [Velocidex](https://www.velocidex.com/) DFIR binary |
| **Velociraptor Claw Edition** | THIS project - deployment/management platform |
| **VelociraptorMCPServer** | The MCP server from Claw Edition (NOT the Velociraptor binary) |
| **Velociraptor binary** | The `velociraptor.exe` / `velociraptor` executable from Velocidex |

---

## Quick Start

### 1. Start Windows VM (if needed)
```bash
# Start Windows 11 VM
prlctl start "Windows 11"

# Verify status
prlctl list "Windows 11"

# Stop when done
prlctl stop "Windows 11"
```

### 2. Build & Run MCP Server

**CRITICAL**: Always build from the canonical location `apps/macos-legacy/`

```bash
# Navigate to canonical macOS Swift root
cd /Users/brodynielsen/GitRepos/Velociraptor_ClawEdition/apps/macos-legacy

# Build the MCP server
swift build --product VelociraptorMCPServer

# Run with stdio transport (default for Cursor/Claude Desktop)
./.build/debug/VelociraptorMCPServer

# Or run with verbose logging
./.build/debug/VelociraptorMCPServer --verbose --log-level debug

# Run with HTTP transport (experimental)
./.build/debug/VelociraptorMCPServer --transport http --port 3000
```

### 3. Connect from Cursor

Add to `.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "velociraptor-dfir": {
      "command": "/Users/brodynielsen/GitRepos/Velociraptor_ClawEdition/apps/macos-legacy/.build/debug/VelociraptorMCPServer",
      "args": ["--log-level", "info"],
      "env": {}
    }
  }
}
```

### 4. Connect from Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "velociraptor": {
      "command": "/Users/brodynielsen/GitRepos/Velociraptor_ClawEdition/apps/macos-legacy/.build/debug/VelociraptorMCPServer",
      "args": []
    }
  }
}
```

---

## ABSOLUTE CANONICAL PATH RULES (NO EXCEPTIONS)

**Enforcement Context**: These rules apply to all AI agent interactions, documentation updates, build/test commands, and path references.

### Repository Anchors

```yaml
# Repo root anchor
repo_root: /Users/brodynielsen/GitRepos/Velociraptor_ClawEdition/

# Canonical macOS Swift root (SwiftPM + XcodeGen)
macos_canonical: apps/macos-legacy/

# Canonical paths (absolute from repo root)
swift_package:       apps/macos-legacy/Package.swift
xcodegen_config:     apps/macos-legacy/project.yml
app_source:          apps/macos-legacy/VelociraptorMacOS/
unit_tests:          apps/macos-legacy/VelociraptorMacOSTests/
ui_tests:            apps/macos-legacy/VelociraptorMacOSUITests/
mcp_server_source:   apps/macos-legacy/Sources/VelociraptorMCPServer/
mcp_library_source:  apps/macos-legacy/Sources/VelociraptorMCP/
```

### Steering + Knowledge Base Entrypoints

```yaml
# Canonical KB entrypoints (read these FIRST)
kb_index:            steering/CDIF_KB_INDEX.md
kb_manifest:         steering/CDIF_KB_MANIFEST.yaml
workspace_paths:     docs/WORKSPACE_PATH_INDEX.md

# CDIF catalog & test archetypes
cdif_catalog:        apps/macos-legacy/CDIF_TEST_ARCHETYPES.md

# Agent prompt corpus
agent_prompts:       .claude/agents/MACOS_SDLC_AGENT_PROMPTS.md

# macOS steering (gap registry + implementation guide)
gap_registry_hex:    Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md
implementation_guide: Velociraptor_macOS_App/steering/MACOS-IMPLEMENTATION-GUIDE.md

# MCP agent config
mcp_agent_config:    .claude/agents/mcp/agent-configs.yaml
```

### Legacy Path Translation

**LEGACY PATHS ARE NON-CANONICAL**. The root-level `VelociraptorMacOS/` is a non-canonical snapshot. **DO NOT** use it as the target of build/test/run commands.

**Translation Rules**:
1. If a user/doc mentions a legacy path, you **MUST**:
   - Map legacy → canonical using `steering/CDIF_KB_MANIFEST.yaml:path_aliases`
   - Output **canonical paths only**
   - Add a one-line "alias mapping" note

**Example Aliases** (from KB manifest):
```yaml
# FROM (legacy)                          → TO (canonical)
VelociraptorMacOS/README.md              → apps/macos-legacy/README.md
VelociraptorMacOS/project.yml            → apps/macos-legacy/project.yml
VelociraptorMacOS/VelociraptorMacOS/     → apps/macos-legacy/VelociraptorMacOS/
Velociraptor_macOS_App/VelociraptorMacOS/ → apps/macos-legacy/VelociraptorMacOS/
```

---

## Knowledge Base Search Contract (PATH-CORRECT + FAST)

### Search Strategy

1. **Consult human index first**: `steering/CDIF_KB_INDEX.md`
2. **Use machine manifest for roots/exclusions**: `steering/CDIF_KB_MANIFEST.yaml`
3. **Output canonical paths only** + minimal working commands + verification gate

### KB Roots (where CDIF knowledge lives)

```yaml
roots:
  - steering/
  - .kiro/steering/
  - Velociraptor_macOS_App/steering/
  - apps/macos-legacy/          # CDIF catalog + TestingAgent + MCP sources
  - docs/
  - .claude/agents/
  - .github/agents/
```

### Exclusions (DO NOT search)

```yaml
exclude_globs:
  - "**/node_modules/**"
  - "**/.build/**"              # Swift build artifacts
  - "**/.swiftpm/**"            # SwiftPM cache
  - "**/DerivedData/**"         # Xcode build
  - "**/Packages/**"
  - "**/.git/**"
  - "tests/results/**"          # Ephemeral test artifacts (DO NOT COMMIT)
```

### Search Template (ripgrep from repo root)

```bash
rg -n --hidden --no-ignore-vcs \
  --glob='!**/node_modules/**' \
  --glob='!**/.build/**' \
  --glob='!**/.swiftpm/**' \
  --glob='!**/DerivedData/**' \
  --glob='!**/TestResults/**' \
  --glob='!**/tests/results/**' \
  "SEARCH_TERM" \
  steering docs apps/macos-legacy Velociraptor_macOS_App .kiro/steering .claude/agents .github/agents
```

---

## Build / Test / Run Commands (CANONICAL PATHS ONLY)

**CRITICAL**: All macOS Swift build/test/run commands **MUST** be anchored to `apps/macos-legacy/`.

### Build Commands

```bash
# Always cd to canonical root first
cd /Users/brodynielsen/GitRepos/Velociraptor_ClawEdition/apps/macos-legacy

# Build all products (app + MCP server)
swift build

# Build specific products
swift build --product VelociraptorMacOS
swift build --product VelociraptorMCPServer

# Build for release
swift build -c release

# Clean build
swift package clean
```

### Test Commands

```bash
cd /Users/brodynielsen/GitRepos/Velociraptor_ClawEdition/apps/macos-legacy

# Run all tests
swift test

# Run specific test targets
swift test --filter VelociraptorMacOSTests
swift test --filter VelociraptorMacOSUITests

# Run with coverage
swift test --enable-code-coverage
```

### XcodeGen (if using Xcode)

```bash
cd /Users/brodynielsen/GitRepos/Velociraptor_ClawEdition/apps/macos-legacy

# Generate Xcode project from project.yml
xcodegen generate

# Open in Xcode
open VelociraptorMacOS.xcodeproj
```

---

## MCP Server Capabilities

### Available Tools

The Velociraptor MCP server exposes 5 DFIR tools:

1. **`velociraptor_generate_vql`**
   - Generate VQL queries for forensic analysis
   - Params: `objective` (required), `platform`, `output_format`, `include_explanation`
   - Use when: Need to collect forensic artifacts, hunt IOCs, analyze system state

2. **`velociraptor_suggest_artifacts`**
   - AI-powered artifact suggestions based on incident type
   - Params: `incident_type` (required), `platform`, `urgency`, `scope`
   - Incident types: ransomware, apt, malware, insider_threat, data_exfiltration, compliance_audit, etc.
   - Use when: Building collection plan for incident response

3. **`velociraptor_plan_deployment`**
   - Create comprehensive Velociraptor deployment plan
   - Params: `deployment_type` (required), `environment`, `security_requirements`
   - Types: standalone, server_client, cloud_aws, cloud_azure, cloud_gcp, kubernetes, docker
   - Use when: Planning new deployment or scaling existing infrastructure

4. **`velociraptor_analyze_timeline`**
   - Analyze forensic timeline data to identify suspicious activities
   - Params: `time_range` (required), `focus_areas`, `known_iocs`
   - Use when: Correlating events across multiple sources, building attack timeline

5. **`velociraptor_create_ir_package`**
   - Create self-contained incident response collector for offline collection
   - Params: `package_name`, `target_platforms`, `artifacts` (all required), `output_format`, `include_memory`
   - Use when: Need offline collector for air-gapped systems or quick triage

### Available Prompts

The server provides 4 interactive prompts (multi-turn conversations):

1. **`incident_response`** - Start incident response workflow with AI guidance
2. **`forensic_analysis`** - Begin forensic analysis session with step-by-step guidance
3. **`vql_helper`** - Interactive help writing VQL queries
4. **`deployment_wizard`** - Interactive Velociraptor deployment planning wizard

### Available Resources

Static documentation resources:

1. **`velociraptor://docs/vql-reference`** - VQL Quick Reference
2. **`velociraptor://docs/artifacts`** - Artifact Catalog
3. **`velociraptor://docs/playbooks`** - Incident Response Playbooks

---

## Default Workflow: "WHERE IS X / WHAT DOC COVERS Y"

When an agent needs to locate documentation or resolve paths:

1. **Consult** `steering/CDIF_KB_INDEX.md` (human-readable index)
2. **Use** `steering/CDIF_KB_MANIFEST.yaml` to confirm roots/exclusions and resolve aliases
3. **Output** canonical paths only + minimal working commands + verification gate

**Example Response Format**:

```markdown
## What Changed
- Located artifact catalog documentation
- Confirmed canonical path using KB manifest

## Impact on Workflow
- CDIF test archetypes are maintained in apps/macos-legacy/CDIF_TEST_ARCHETYPES.md
- This is the authoritative source for FC-*, MAC-*, DET-*, ACC-*, PERF-*, SEC-* archetypes

## Canonical Path
apps/macos-legacy/CDIF_TEST_ARCHETYPES.md

## Verification Gate
rg "CDIF-ARCH-" steering/CDIF_KB_MANIFEST.yaml apps/macos-legacy/CDIF_TEST_ARCHETYPES.md

## Alias Mapping
VelociraptorMacOS/CDIF_TEST_ARCHETYPES.md → apps/macos-legacy/CDIF_TEST_ARCHETYPES.md (legacy snapshot → canonical)
```

---

## Output Format (Every Agent Response)

All agent responses interacting with this repo **MUST** include:

1. **What changed** (new facts ingested)
2. **Impact on prompts/workflow**
3. **Updated canonical prompt(s) or template(s)** (copy/paste ready)
4. **Optional**: MCP payload stubs, CDIF child-object stubs, verification gates

---

## Git State Note Handling

**WARNING**: KB/CDIF fixes in untracked files won't persist until committed.

If you discover untracked KB/CDIF changes:
- **Warn the user**: "KB updates in `steering/FOO.md` are untracked and won't persist."
- **Offer a consolidated commit plan** (no code changes, only docs/KB)
- **Do NOT auto-commit** without explicit user approval

---

## Troubleshooting

### MCP Server Won't Start

```bash
# Check Swift version (needs 6.0+)
swift --version

# Rebuild from clean state
cd apps/macos-legacy
swift package clean
swift build --product VelociraptorMCPServer

# Check for port conflicts (if using HTTP)
lsof -i :3000
```

### Windows VM Issues

```bash
# Check VM status
prlctl list "Windows 11"

# Suspend (faster than stop)
prlctl suspend "Windows 11"

# Resume from suspend
prlctl resume "Windows 11"

# Force stop if hung
prlctl stop "Windows 11" --kill
```

### Path Resolution Issues

If an agent outputs a legacy path:
1. **Stop immediately**
2. Consult `steering/CDIF_KB_MANIFEST.yaml:path_aliases`
3. Translate to canonical path
4. Include alias mapping note in response

---

## Related Documentation

- **KB Index**: `steering/CDIF_KB_INDEX.md`
- **KB Manifest**: `steering/CDIF_KB_MANIFEST.yaml`
- **Workspace Paths**: `docs/WORKSPACE_PATH_INDEX.md`
- **CDIF Archetypes**: `apps/macos-legacy/CDIF_TEST_ARCHETYPES.md`
- **Agent Prompts**: `.claude/agents/MACOS_SDLC_AGENT_PROMPTS.md`
- **MCP Config**: `.claude/agents/mcp/agent-configs.yaml`

---

## Version History

- **2026-02-04**: Initial runbook created
  - Consolidated canonical path rules from code block (6-64)
  - Added MCP server build/run instructions
  - Added Windows VM management (prlctl)
  - Added KB search contract and exclusions
  - Added agent output format requirements
