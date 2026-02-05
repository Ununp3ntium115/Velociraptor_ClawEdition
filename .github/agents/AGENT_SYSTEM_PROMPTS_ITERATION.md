 # Agent System Prompts Iteration Plan
 
 **Date**: 2026-02-05
 **Owner**: Implementation Agent (Docs)
**Status**: Completed
 
 ---
 
 ## Objective
 Add missing system prompt documentation for the HiQ swarm agents that are not yet represented in `.github/agents/`.
 
 ## Gap Analysis (TDD First)
 **Observed Gap**:
 - The agents directory currently documents only the macOS Development Agent.
 - The repository lacks documented system prompts for the remaining core swarm roles.
 
 **Planned Closure**:
 - Create one agent prompt file per role.
 - Update `.github/agents/README.md` to list each new agent.
 
 ## Planned Files
 - `.github/agents/implementation-agent.md`
 - `.github/agents/testing-agent.md`
 - `.github/agents/qa-agent.md`
 - `.github/agents/uat-agent.md`
 - `.github/agents/macos-platform-qa-agent.md`
 - `.github/agents/security-testing-agent.md`
 - `.github/agents/gap-analysis-agent.md`
 - `.github/agents/fix-all-gaps-orchestrator.md`
 - `.github/agents/README.md` (update list)
 
 ## Test Cases (Defined Before Implementation)
 1. **Agent Doc Presence**: Each planned file exists in `.github/agents/`.
 2. **Section Completeness**: Each agent doc includes:
    - Agent Purpose
    - Implementation Context
    - Platform/Hard Rules
    - Workflow
    - Outputs
    - Quick Reference
 3. **README Listing**: `.github/agents/README.md` lists all new agents with file names and roles.
 4. **Prompt Fidelity**: Each doc preserves the provided system prompt content without scope expansion.
 
 ## Out of Scope
 - No code or runtime behavior changes.
 - No new dependencies.
 - No edits to PowerShell or Electron runtime.
 
 ---
 
## Implementation Results
**Completed**:
- Added system prompt documentation for all core swarm roles.
- Updated `.github/agents/README.md` with new agent listings.

**Files Created**:
- `.github/agents/implementation-agent.md`
- `.github/agents/testing-agent.md`
- `.github/agents/qa-agent.md`
- `.github/agents/uat-agent.md`
- `.github/agents/macos-platform-qa-agent.md`
- `.github/agents/security-testing-agent.md`
- `.github/agents/gap-analysis-agent.md`
- `.github/agents/fix-all-gaps-orchestrator.md`

**Files Updated**:
- `.github/agents/README.md`

**Notes**:
- Changes are documentation-only and preserve the provided prompt content.

---

## Validation Results
1. **Agent Doc Presence**: PASS
   - Files present under `.github/agents/` for all planned roles.
2. **Section Completeness**: PASS
   - Each doc includes Agent Purpose, Implementation Context, Platform/Hard Rules,
     Workflow, Required Outputs, and Quick Reference.
3. **README Listing**: PASS
   - `.github/agents/README.md` lists all added agents.
4. **Prompt Fidelity**: PASS
   - Content mirrors the provided system prompts without scope expansion.

## Test / CI Notes
- `pwsh -v`: FAILED (pwsh not installed in environment)
- `powershell -v`: FAILED (PowerShell not installed in environment)
- `gh workflow run test-scripts.yml --ref cursor/gap-resolution-framework-fe5c`: FAILED (HTTP 403)

---

**Next Step**: None (documentation-only change set complete).
