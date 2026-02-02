# CDIF Knowledge Base Index

**Document**: `steering/CDIF_KB_INDEX.md`  
**Purpose**: Master index of all governance, tracking, and policy documents  
**Last Updated**: January 23, 2026

---

## Document Categories

### AGENT PROMPTS & ORCHESTRATION
- `.claude/agents/CDIF_GOVERNANCE_AGENT.md` — Authoritative governance agent prompt
- `.claude/agents/MACOS_SDLC_AGENT_PROMPTS.md` — macOS SDLC agent prompts
- `.claude/agents/mcp/agent-configs.yaml` — MCP agent configurations

### ISSUE CLOSE-OUT & PRODUCTION READINESS
- `steering/ISSUE_CLOSEOUT_TODO.md` — Authoritative close-out checklist
- `steering/GITHUB_ISSUES_STATUS.md` — Evidence/status index
- `steering/ISSUE_CLOSEOUT_GOVERNANCE.md` — Governance policy
- `steering/PRODUCTION_READINESS_DECLARATION.md` — Production release declaration
- `steering/MACOS_REINDEX_ANALYSIS.md` — Gap reindex analysis

### MACOS IMPLEMENTATION
- `steering/MACOS_MASTER_ITERATION_PLAN.md` — Master implementation plan
- `steering/MACOS_PRODUCTION_COMPLETE.md` — Production status declaration
- `steering/MACOS_CODE_REVIEW_ANALYSIS.md` — Code review findings
- `steering/MACOS_GAP_ANALYSIS_ITERATION_2.md` — Gap analysis results
- `steering/MACOS_IMPLEMENTATION_COMPLETE.md` — Implementation summary
- `steering/MACOS_VERIFICATION_SUMMARY.md` — Verification results

### QA & TESTING
- `steering/MACOS_QA_TEST_PLAN.md` — QA test plan
- `steering/MACOS_UI_CONTROL_INVENTORY.md` — UI control inventory
- `docs/QA_QUALITY_GATE.md` — Quality gate criteria
- `docs/QA_QUICK_REFERENCE.md` — QA quick reference

### PRODUCT & STRATEGY
- `steering/product.md` — Product definition
- `steering/tech.md` — Technical architecture
- `steering/structure.md` — Repository structure
- `steering/strategic-roadmap-2025-2027.md` — Strategic roadmap

### DEVELOPER DOCUMENTATION
- `docs/MACOS_CONTRIBUTING.md` — macOS contribution guide
- `docs/PARALLELS_MCP_SETUP.md` — Parallels MCP setup
- `VelociraptorMacOS/README.md` — macOS app README

### CI/CD & AUTOMATION
- `.github/workflows/macos-build.yml` — macOS build workflow
- `.github/workflows/macos-testing-agent.yml` — Testing agent workflow
- `VelociraptorMacOS/scripts/create-release.sh` — Release script

---

## Quick Reference

| Task | Document |
|------|----------|
| Close an issue | `steering/ISSUE_CLOSEOUT_TODO.md` |
| Check issue evidence | `steering/GITHUB_ISSUES_STATUS.md` |
| Understand close-out policy | `steering/ISSUE_CLOSEOUT_GOVERNANCE.md` |
| Review macOS implementation | `steering/MACOS_PRODUCTION_COMPLETE.md` |
| Run QA tests | `steering/MACOS_QA_TEST_PLAN.md` |
| Contribute to macOS app | `docs/MACOS_CONTRIBUTING.md` |

---

## Authoritative Documents

These documents are the single source of truth for their domains:

| Domain | Authoritative Document |
|--------|----------------------|
| Issue Close-Out | `steering/ISSUE_CLOSEOUT_TODO.md` |
| Close-Out Policy | `steering/ISSUE_CLOSEOUT_GOVERNANCE.md` |
| macOS Implementation | `steering/MACOS_PRODUCTION_COMPLETE.md` |
| Product Definition | `steering/product.md` |
| Repository Structure | `steering/structure.md` |

---

## Document Hierarchy

```
steering/
├── CDIF_KB_INDEX.md (this file)
├── CDIF_KB_MANIFEST.yaml
│
├── Close-Out/
│   ├── ISSUE_CLOSEOUT_TODO.md
│   ├── ISSUE_CLOSEOUT_GOVERNANCE.md
│   └── GITHUB_ISSUES_STATUS.md
│
├── macOS/
│   ├── MACOS_PRODUCTION_COMPLETE.md
│   ├── MACOS_MASTER_ITERATION_PLAN.md
│   ├── MACOS_CODE_REVIEW_ANALYSIS.md
│   └── MACOS_*.md
│
└── Strategy/
    ├── product.md
    ├── tech.md
    └── strategic-roadmap-*.md
```

---

*This index is maintained as part of the CDIF (Claude Documentation and Information Framework).*
