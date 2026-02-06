# Workspace Path Index (Post-Reorganization)

**Purpose**: Single source of truth for where files live after the PowerShell/file sprawl reorganization. Use these paths in code, docs, and automation. Root folder contains only entrypoints and top-level config; implementation lives in `scripts/`, `lib/`, `apps/`, `docs/`, etc.

**Last updated**: 2026-02-02

---

## Read CDIF structure first

When working with macOS agents, gap analysis, or test archetypes:

1. **Read the CDIF catalog structure**: `apps/macos-app/CDIF_TEST_ARCHETYPES.md` — start with the **CDIF Structure (read first)** section. It defines the document layout, the relationship between test archetypes (FC-*, MAC-*, etc.) and the parent/child registry (CDIF-ARCH-*, CDIF-IMPL-* in `.claude/agents/MACOS_SDLC_AGENT_PROMPTS.md`), and path resolution rules.
2. **Use the Path Reference Index** inside that catalog for all canonical repo paths (steering, gap docs, deployment, tests, build, agents).
3. **Use the Steering KB index**: `steering/CDIF_KB_INDEX.md` to find the right schematics/workflows quickly (and to avoid searching vendor/build output).
4. **This file** (`docs/WORKSPACE_PATH_INDEX.md`) is the workspace-wide path index; the CDIF catalog’s Path Reference Index mirrors and extends it for CDIF/agent use.

---

## Root folder (canonical contents only)

Only these belong at repository root:

| Item | Path | Notes |
|------|------|--------|
| Repo config | `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `package.json`, `VERSION`, `.gitignore` | Entry docs and metadata |
| Workspace | `*.code-workspace` | VS Code / Cursor workspaces |
| Top-level dirs | `apps/`, `build/`, `cloud/`, `containers/`, `docs/`, `examples/`, `lib/`, `scripts/`, `steering/`, `tests/`, `tools/`, `archive/`, `Velociraptor_macOS_App/`, `VelociraptorMacOS/` | No loose scripts or modules at root |
| Release artifact | `velociraptor-setup-scripts-*.tar.gz` (optional at root; prefer `build/` or gitignore) | |

**Do not** add new `.ps1`, `.psm1`, or `.psd1` at root. Do not add new loose `.md` at root (use `docs/` or `steering/`). Add them under `scripts/` or `lib/` and reference via this index. When moving or adding files, update this index and any code that references the old path (see "How to reference in code" below).

---

## Canonical path reference (where things are now)

### Deployment scripts (PowerShell)

| Logical name | Current path | Old location (pre-reorg) |
|--------------|--------------|---------------------------|
| Standalone deploy | `scripts/Deploy_Velociraptor_Standalone.ps1` | (root) |
| Server deploy | `scripts/Deploy_Velociraptor_Server.ps1` | (root) |
| Cleanup | `scripts/Cleanup_Velociraptor.ps1` | (root) |
| Offline collector prep | `scripts/Prepare_OfflineCollector_Env.ps1` | (root) |
| Other Deploy_* | `scripts/Deploy_Velociraptor_*.ps1` | (root) |

### GUI scripts

| Logical name | Current path | Old location |
|--------------|--------------|--------------|
| Main GUI (canonical) | `apps/gui/VelociraptorGUI.ps1` | `gui/VelociraptorGUI.ps1` |
| Install-clean GUI | `scripts/VelociraptorGUI-InstallClean.ps1` | (root) |
| Incident response GUI | `scripts/IncidentResponseGUI-*.ps1` (see scripts/) | (root) |

### PowerShell module (root module and submodules)

| Logical name | Current path | Old location |
|--------------|--------------|--------------|
| Root module manifest | `lib/VelociraptorSetupScripts.psd1` | (root) |
| Root module script | `lib/VelociraptorSetupScripts.psm1` | (root) |
| Deployment module | `lib/modules/VelociraptorDeployment/VelociraptorDeployment.psd1` | `modules/VelociraptorDeployment/` |
| Governance module | `lib/modules/VelociraptorGovernance/VelociraptorGovernance.psd1` | `modules/VelociraptorGovernance/` |
| Compliance module | `lib/modules/VelociraptorCompliance/` | (same under modules/) |
| Other nested modules | `lib/modules/<ModuleName>/` | `modules/<ModuleName>/` |

### Documentation

| Logical name | Current path |
|--------------|--------------|
| All project docs | `docs/` |
| Steering / iteration | `steering/` (and `.kiro/steering/`) |
| Gap / analysis docs | `docs/` (e.g. `docs/GAP-ANALYSIS-EXECUTIVE-SUMMARY.md` after move) |

### macOS app and steering (canonical vs snapshot)

| Logical name | Current path | Notes |
|--------------|--------------|-------|
| **macOS app (canonical build + tests)** | `apps/macos-app/` | SwiftPM + XcodeGen app (`apps/macos-app/VelociraptorMacOS/`), tests (`VelociraptorMacOSTests/`, `VelociraptorMacOSUITests/`), CDIF + MCP server sources |
| **macOS app (root snapshot / lightweight copy)** | `VelociraptorMacOS/` | Non-canonical copy for reference; do not use as the primary build/test source |
| **macOS steering / gap registry** | `Velociraptor_macOS_App/steering/` | Gap registry and implementation guide: `HEXADECIMAL-GAP-REGISTRY.md`, `MACOS-IMPLEMENTATION-GUIDE.md` |
| **macOS code review / analysis** | `steering/MACOS_CODE_REVIEW_ANALYSIS.md` | Code review and gap analysis docs |

### CDIF and agents (read CDIF structure first)

| Logical name | Current path | Referenced by |
|--------------|--------------|---------------|
| **CDIF catalog (read structure first)** | `apps/macos-app/CDIF_TEST_ARCHETYPES.md` | Agents, macOS QA, gap analysis; contains CDIF Structure and Path Reference Index |
| **CDIF parent/child registry** | `.claude/agents/MACOS_SDLC_AGENT_PROMPTS.md` | CDIF-ARCH-*, CDIF-IMPL-* definitions |
| **Gap registry (hex)** | `Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md` | Gap analysis agent |
| Path index (this doc) | `docs/WORKSPACE_PATH_INDEX.md` | Code and docs that resolve paths |

### Cloud, containers, tests

| Logical name | Current path |
|--------------|--------------|
| AWS deploy | `cloud/aws/Deploy-VelociraptorAWS.ps1` |
| Azure deploy | `cloud/azure/` |
| Containers | `containers/docker/`, `containers/kubernetes/` |
| Unit tests | `tests/unit/` |
| Integration tests | `tests/integration/` |
| Security tests | `tests/security/` |
| Build / release assets | `build/` |

### Generated artifacts (gitignored; do not commit)

These paths are **expected to be created during builds/tests** and should be treated as ephemeral artifacts.

| Logical name | Path | Notes |
|--------------|------|-------|
| Test run artifacts | `tests/results/` | Generated per run; keep as CI artifacts or link from GitHub issues |
| Node dependencies | `**/node_modules/**` | Generated by `npm install`; do not commit |
| Swift build artifacts | `.build/`, `.swiftpm/`, `DerivedData/` | Generated by SwiftPM/Xcode |

---

## How to reference in code

- **From repo root**: Use `scripts/Deploy_Velociraptor_Standalone.ps1`, `lib/VelociraptorSetupScripts.psd1`, `apps/gui/VelociraptorGUI.ps1`.
- **From `tests/*`**: Use `Join-Path $PSScriptRoot '..\..\scripts\Deploy_Velociraptor_Standalone.ps1'` (and similarly for `lib\modules\...`).
- **From `scripts/*`**: Use `Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'scripts\Deploy_Velociraptor_Standalone.ps1'` or resolve repo root once and use `$RepoRoot\scripts\...`, `$RepoRoot\lib\...`.
- **Module import**: `Import-Module .\lib\VelociraptorSetupScripts.psd1 -Force` when run from repo root.

---

## Release / package layout (flat copy)

Incident packages and `build/releases/` create a **flat** layout where `Deploy_*.ps1`, `gui/`, and `VelociraptorSetupScripts.psm1` appear at the package root. That layout is intentional for end users. The **source** repo uses the paths above; release scripts (e.g. `build/releases/create-release-zip.ps1`, `scripts/Build-IncidentResponsePackages.ps1`) copy from these canonical paths into the flat structure.

---

## Continue / next steps

- **Run tests** (from repo root): `.\tests\Run-Tests.ps1` or `.\tests\Run-Tests.ps1 -TestType Unit`. Requires Pester (`Install-Module Pester -Scope CurrentUser` if missing).
- **Deploy**: `.\scripts\Deploy_Velociraptor_Standalone.ps1` or `.\scripts\Deploy_Velociraptor_Server.ps1`.
- **GUI**: `.\apps\gui\VelociraptorGUI.ps1`.
- **Module**: `Import-Module .\lib\VelociraptorSetupScripts.psd1 -Force`.
- **macOS app (Swift)**: App source at `VelociraptorMacOS/`; gap registry and steering at `Velociraptor_macOS_App/steering/`; CDIF and legacy bundle at `apps/macos-app/`.
- **CDIF / agents**: Read `apps/macos-app/CDIF_TEST_ARCHETYPES.md` (CDIF Structure section first), then use the Path Reference Index there and this file for all paths.
- **After moving or adding files**: Update this index and `apps/macos-app/CDIF_TEST_ARCHETYPES.md` Path Reference Index; update any code that referenced the old path.
