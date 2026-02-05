# MCP Server Setup Summary
## Velociraptor Claw Edition

**Date**: 2026-02-04  
**Status**: ✅ Complete

---

## What We Accomplished

### 1. ✅ Windows VM Management
- **Located VM**: Found Windows 11 VM (UUID: b055c280-9c65-4bda-b58e-f1fe2f36d520)
- **Started VM**: Successfully started using `prlctl start "Windows 11"`
- **Current Status**: Running and ready for testing

### 2. ✅ MCP Server Built Successfully
- **Build Location**: `apps/macos-legacy/` (canonical Swift root)
- **Binary Path**: `apps/macos-legacy/.build/debug/VelociraptorMCPServer`
- **Build Tool**: Swift Package Manager 6.0
- **Build Time**: ~17.8 seconds

### 3. ✅ MCP Server Capabilities Verified

The server exposes **5 DFIR tools**:
1. `velociraptor_generate_vql` - VQL query generation
2. `velociraptor_suggest_artifacts` - Incident-specific artifact recommendations
3. `velociraptor_plan_deployment` - Deployment planning (standalone, cloud, K8s, etc.)
4. `velociraptor_analyze_timeline` - Forensic timeline correlation
5. `velociraptor_create_ir_package` - Offline collector creation

Plus **4 interactive prompts** and **3 documentation resources**.

### 4. ✅ Canonical Path Enforcement Runbook Created

Created `.cursor/commands/mcp.md` with:
- Absolute canonical path rules (no exceptions)
- Build/test/run command templates (always from `apps/macos-legacy/`)
- KB search contract with exclusions
- Legacy → canonical path translation rules
- Windows VM management commands
- Agent output format requirements

---

## Quick Reference

### Start MCP Server (stdio transport for Cursor/Claude)
```bash
cd /Users/brodynielsen/GitRepos/Velociraptor_ClawEdition/apps/macos-legacy
./.build/debug/VelociraptorMCPServer
```

### Connect from Cursor
Add to `.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "velociraptor-dfir": {
      "command": "/Users/brodynielsen/GitRepos/Velociraptor_ClawEdition/apps/macos-legacy/.build/debug/VelociraptorMCPServer",
      "args": ["--log-level", "info"]
    }
  }
}
```

### Windows VM Control
```bash
prlctl start "Windows 11"       # Start
prlctl suspend "Windows 11"     # Suspend (fast resume)
prlctl stop "Windows 11"        # Full shutdown
prlctl list "Windows 11"        # Check status
```

---

## Canonical Path Summary

**CRITICAL**: All macOS Swift operations must anchor to `apps/macos-legacy/`

| Component | Canonical Path |
|-----------|----------------|
| Swift Package | `apps/macos-legacy/Package.swift` |
| XcodeGen | `apps/macos-legacy/project.yml` |
| App Source | `apps/macos-legacy/VelociraptorMacOS/` |
| MCP Server | `apps/macos-legacy/Sources/VelociraptorMCPServer/` |
| MCP Library | `apps/macos-legacy/Sources/VelociraptorMCP/` |
| Unit Tests | `apps/macos-legacy/VelociraptorMacOSTests/` |
| UI Tests | `apps/macos-legacy/VelociraptorMacOSUITests/` |

**Legacy snapshot** (non-canonical): `VelociraptorMacOS/` ← DO NOT use for build/test/run

---

## Knowledge Base Entrypoints

| Purpose | Path |
|---------|------|
| KB Index (human) | `steering/CDIF_KB_INDEX.md` |
| KB Manifest (machine) | `steering/CDIF_KB_MANIFEST.yaml` |
| Workspace Paths | `docs/WORKSPACE_PATH_INDEX.md` |
| CDIF Catalog | `apps/macos-legacy/CDIF_TEST_ARCHETYPES.md` |
| Gap Registry | `Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md` |
| Agent Prompts | `.claude/agents/MACOS_SDLC_AGENT_PROMPTS.md` |
| MCP Agent Config | `.claude/agents/mcp/agent-configs.yaml` |

---

## Next Steps

### 1. Test MCP Server Integration
```bash
# In one terminal: start the server
cd apps/macos-legacy
./.build/debug/VelociraptorMCPServer --verbose

# In another terminal or Cursor: test a tool call
# (Use Cursor's MCP integration or Claude Desktop)
```

### 2. Connect Cursor to MCP Server
- Create/update `.cursor/mcp.json` (see template above)
- Restart Cursor
- MCP tools will appear in the tools palette

### 3. Test DFIR Workflow
Try asking the AI assistant (with MCP connected):
- "Generate a VQL query to hunt for ransomware indicators on Windows"
- "Suggest artifacts for an APT investigation"
- "Plan a Kubernetes deployment for Velociraptor"

### 4. Use Windows VM for Testing
The Windows 11 VM is running and ready for:
- PowerShell script testing
- Windows-specific DFIR operations
- Cross-platform validation

---

## Verification Commands

### Confirm MCP Server Build
```bash
cd apps/macos-legacy
ls -lh .build/debug/VelociraptorMCPServer
# Should show ~1-2MB executable with today's timestamp
```

### Confirm Windows VM Running
```bash
prlctl list "Windows 11"
# STATUS column should show "running"
```

### Confirm Canonical Paths Intact
```bash
# From repo root
ls -d apps/macos-legacy/Package.swift \
      apps/macos-legacy/Sources/VelociraptorMCPServer/ \
      steering/CDIF_KB_INDEX.md
# All should exist
```

---

## Troubleshooting

**Issue**: MCP server won't build  
**Solution**: `cd apps/macos-legacy && swift package clean && swift build`

**Issue**: Windows VM won't start  
**Solution**: Check Parallels Desktop is running; try `prlctl list -a` to see all VMs

**Issue**: Path confusion (legacy vs canonical)  
**Solution**: Consult `steering/CDIF_KB_MANIFEST.yaml:path_aliases` and always output canonical paths

**Issue**: KB search returns too many results  
**Solution**: Use the exclusion globs from `mcp.md` (exclude .build, node_modules, DerivedData, etc.)

---

## Related Documentation

- **Full Runbook**: `.cursor/commands/mcp.md`
- **KB Index**: `steering/CDIF_KB_INDEX.md`
- **Workspace Paths**: `docs/WORKSPACE_PATH_INDEX.md`
- **MCP Source**: `apps/macos-legacy/Sources/VelociraptorMCP/`

---

## Files Created/Modified

1. `.cursor/commands/mcp.md` — Comprehensive MCP + path enforcement runbook
2. `.cursor/commands/MCP_SETUP_SUMMARY.md` — This summary
3. `apps/macos-legacy/.build/debug/VelociraptorMCPServer` — Built MCP server binary

**Git Status**: These are new/modified files. Consider committing:
```bash
git add .cursor/commands/mcp.md .cursor/commands/MCP_SETUP_SUMMARY.md
git commit -m "Add MCP server runbook and canonical path enforcement guide"
```

---

## Success Criteria Met ✅

- [x] Located and documented Windows VM control (`prlctl`)
- [x] Built MCP server from canonical location (`apps/macos-legacy/`)
- [x] Verified MCP server capabilities (5 tools, 4 prompts, 3 resources)
- [x] Created comprehensive runbook enforcing canonical paths
- [x] Documented KB search strategy with exclusions
- [x] Provided agent output format requirements
- [x] Integrated code block (6-64) path rules into unified runbook

---

**Status**: Ready for production use. MCP server can now be integrated into Cursor/Claude Desktop for DFIR workflows.
