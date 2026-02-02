# CDIF / Steering Knowledge Base Index

**Purpose**: Make CDIF + Steering knowledge (schematics, workflows, plans) discoverable and **path-correct** after cleanup/reorg. This is the canonical entrypoint for humans and agents.

---

## Start here (canonical entrypoints)

| Topic | Start here | Notes |
|------|------------|------|
| **Canonical paths (repo-wide)** | `docs/WORKSPACE_PATH_INDEX.md` | Single source of truth for “where things live now” |
| **KB manifest (machine-readable)** | `steering/CDIF_KB_MANIFEST.yaml` | YAML manifest with anchors, exclusions, and doc IDs |
| **CDIF test archetypes (catalog + path index)** | `apps/macos-legacy/CDIF_TEST_ARCHETYPES.md` | Defines FC/MAC/DET/ACC/PERF/SEC archetypes + CDIF path rules |
| **Gap registry (hex)** | `Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md` | Gap IDs, priorities, closure criteria |
| **macOS implementation guide (hex)** | `Velociraptor_macOS_App/steering/MACOS-IMPLEMENTATION-GUIDE.md` | Master plan for gap-driven delivery |
| **macOS implementation guide (steering copy)** | `steering/macos-app/macOS-Implementation-Guide.md` | Steering-layer copy used by iteration workflows |

---

## KB roots (where “CDIF knowledge” lives)

- **Primary steering**: `steering/`
- **Kiro steering**: `.kiro/steering/`
- **macOS steering**: `Velociraptor_macOS_App/steering/`
- **CDIF catalog + Testing Agent docs**: `apps/macos-legacy/` (CDIF catalog + TestingAgent sources/docs)

---

## Exclusions (do NOT treat as KB content)

These paths create noise and can break “search the KB” workflows:

- **Vendor/build output**: `**/node_modules/**`, `.build/`, `.swiftpm/`, `DerivedData/`
- **Ephemeral test artifacts**: `tests/results/` (generated per run; **do not commit**)

If you need evidence from a run, attach/link it from the GitHub issue (or CI artifacts) instead of relying on a committed `tests/results/` tree.

---

## macOS CDIF workflow map (how docs connect)

- **Gap registry** → `Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md`
- **Implementation plan / phases** → `Velociraptor_macOS_App/steering/MACOS-IMPLEMENTATION-GUIDE.md` and `steering/macos-app/macOS-Implementation-Guide.md`
- **Test archetypes / validation language** → `apps/macos-legacy/CDIF_TEST_ARCHETYPES.md`
- **Automation expectations** → `steering/MACOS_QA_TEST_PLAN.md` and `steering/MACOS_UI_CONTROL_INVENTORY.md`
- **Closeout evidence** → GitHub issues + CI artifacts (avoid committing `tests/results/`)

---

## Document index (curated, path-correct)

### Core (paths, structure, tech, product)

- `docs/WORKSPACE_PATH_INDEX.md` — workspace-wide canonical paths (post-reorg)
- `steering/structure.md` — project structure & directory expectations
- `steering/tech.md` — build/test commands and tech stack
- `steering/product.md` — product overview and current phase
- `.kiro/steering/structure.md`, `.kiro/steering/tech.md`, `.kiro/steering/product.md` — assistant steering equivalents

### CDIF + macOS Testing Agent (implementation)

- `apps/macos-legacy/CDIF_TEST_ARCHETYPES.md` — CDIF archetype catalog + path reference index
- `apps/macos-legacy/TESTING_AGENT_CI_CD_GUIDE.md` — CI/CD + evidence conventions for TestingAgent
- `apps/macos-legacy/TESTING_AGENT_EXAMPLES.md` — example runs and report formats
- `apps/macos-legacy/VelociraptorMacOS/TestingAgent/README.md` — TestingAgent architecture (within macos-legacy)
- `.claude/agents/mcp/agent-configs.yaml` — MCP/CDIF agent anchor paths (must match `docs/WORKSPACE_PATH_INDEX.md`)
- `.github/agents/macos-development-agent.md` — GitHub agent playbook (development conventions + commands)

### macOS (gaps, implementation, QA, verification)

- `Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md` — authoritative gap registry (hex)
- `Velociraptor_macOS_App/steering/MACOS-IMPLEMENTATION-GUIDE.md` — authoritative implementation guide
- `steering/macos-app/macOS-Implementation-Guide.md` — steering copy of macOS guide
- `steering/MACOS_MASTER_ITERATION_PLAN.md` — iteration plan / sequencing
- `steering/MACOS_GAP_ANALYSIS_ITERATION_2.md` — gap analysis iteration
- `steering/MACOS_PRODUCTION_READINESS_GAP_ANALYSIS.md` — production readiness analysis
- `steering/MACOS_QA_TEST_PLAN.md` — QA/UA plan (CDIF-aligned)
- `steering/MACOS_UI_CONTROL_INVENTORY.md` — UI control inventory for automation parity
- `steering/MACOS_VERIFICATION_SUMMARY.md` — verification summary
- `steering/MACOS_CODE_REVIEW_ANALYSIS.md` — code review + simplification findings

### Status / closeout tracking

- `steering/GITHUB_ISSUES_STATUS.md` — issue tracking status
- `steering/ISSUE_CLOSEOUT_TODO.md` — closeout checklist
- `steering/outstanding-issues-analysis.md` — known blockers / risks
- `steering/p0-implementation-plan.md`, `steering/p0-implementation-summary.md`, `steering/p0-validation-report.md` — P0 execution
- `steering/p1-implementation-summary.md` — P1 execution

---

## Notation convention (so KB content stays searchable)

For any new/updated CDIF/steering docs, add a small metadata block near the top:

- **KB-ID**: short stable identifier (e.g. `KB-MACOS-QA-PLAN`)
- **KB-Tags**: comma-separated tags (e.g. `macos, qa, cdif, uat, automation`)
- **Scope**: what this doc governs
- **Canonical paths**: any paths this doc is authoritative for (must match `docs/WORKSPACE_PATH_INDEX.md`)
- **Related**: links to relevant gaps/issues/archetypes (e.g. `GAP-0x##`, `FC-002`, `ACC-001`)

