# CDIF Test Archetypes Catalog

## Overview

This catalog defines Common Definition of Issue Format (CDIF) test archetypes for the macOS Testing Agent. Each archetype represents a reusable test pattern for validating gap closure.

---

## CDIF Structure (read first)

**Document layout** (this file):

| Section | Purpose |
|--------|---------|
| **Overview** | What CDIF is and who uses it |
| **CDIF Structure** | This section – document map and registry relationship |
| **Schema Version** | Catalog version and last updated |
| **Archetype Categories** | Test archetypes (FC-*, MAC-*, DET-*, ACC-*, PERF-*, SEC-*) |
| **Usage** | Gap validation and CDIF report generation |
| **Archetype Extension** | How to add new archetypes |
| **Path Reference Index** | Canonical repo paths after workspace reorganization |
| **References** | Links to steering, Testing Agent, path index |

**Relationship to CDIF/CEDIF registry** (parent/child objects):

- **Architecture parent objects** (e.g. `CDIF-ARCH-001`) and **implementation child objects** (e.g. `CDIF-IMPL-001`) are defined in agent prompts (`.claude/agents/MACOS_SDLC_AGENT_PROMPTS.md`). They describe canonical architecture and implementation patterns.
- **This catalog** holds **test archetypes** (FC-001, MAC-001, DET-001, etc.) used for gap validation and CDIF report generation. When closing a gap, agents apply archetypes from here and may create/update child objects in the registry.
- **Path resolution**: All file/path references use `docs/WORKSPACE_PATH_INDEX.md` and the Path Reference Index below. Code and docs must use those canonical paths.

**Rules**:

1. Before writing or moving code, read this structure and `docs/WORKSPACE_PATH_INDEX.md`.
2. Reference files only via the Path Reference Index (or path index); do not assume root-level scripts or modules.
3. When adding archetypes, add them to the correct category and update the Path Reference Index if you introduce new canonical paths.

---

## Schema Version

**Version:** 1.0
**Last Updated:** 2026-02-02

## Archetype Categories

### 1. Functional Correctness Archetypes

#### FC-001: Basic Feature Validation
```yaml
archetype_id: "FC-001"
name: "Basic Feature Validation"
category: "functional"
description: "Validates that a feature works as specified"

test_requirements:
  - unit_tests: true
  - integration_tests: true
  - edge_cases_covered: true
  - error_handling: true

validation_criteria:
  - all_unit_tests_pass: true
  - integration_tests_pass: true
  - no_regressions: true
  - performance_acceptable: true

determinism_requirements:
  - repeatable: true
  - flakiness_threshold: 0.05  # Max 5% failure rate
  - run_count: 3

swift_concurrency:
  - main_actor_ui_updates: true
  - background_tasks_isolated: true
  - no_data_races: true
```

#### FC-002: UI Flow Validation
```yaml
archetype_id: "FC-002"
name: "UI Flow Validation"
category: "functional"
description: "Validates UI navigation and user interaction flows"

test_requirements:
  - ui_tests: true
  - accessibility_identifiers: required
  - keyboard_navigation: true
  - voiceover_compatible: true

validation_criteria:
  - all_screens_reachable: true
  - back_navigation_works: true
  - state_preserved: true
  - animations_complete: true

macos_specific:
  - respects_reduced_motion: true
  - uses_native_controls: true
  - follows_hig: true  # Human Interface Guidelines
```

### 2. macOS Correctness Archetypes

#### MAC-001: Sandbox Compatibility
```yaml
archetype_id: "MAC-001"
name: "Sandbox Compatibility"
category: "macos_correctness"
description: "Validates app works within App Sandbox restrictions"

test_requirements:
  - sandbox_enabled: true
  - entitlements_validated: true
  - file_access_limited: true

validation_criteria:
  - no_sandbox_violations: true
  - uses_security_scoped_bookmarks: true
  - respects_file_permissions: true
  - no_privilege_escalation: true

storage_locations:
  - application_support: "~/Library/Application Support/Velociraptor"
  - caches: "~/Library/Caches/Velociraptor"
  - logs: "~/Library/Logs/Velociraptor"
  - temporary: "/tmp/Velociraptor-*"
```

#### MAC-002: Keychain Integration
```yaml
archetype_id: "MAC-002"
name: "Keychain Integration"
category: "macos_correctness"
description: "Validates proper macOS Keychain usage"

test_requirements:
  - keychain_access: true
  - secure_storage: true
  - credential_lifecycle: true

validation_criteria:
  - passwords_stored_securely: true
  - credentials_retrievable: true
  - keychain_items_removable: true
  - no_plaintext_secrets: true

keychain_operations:
  - save: true
  - retrieve: true
  - update: true
  - delete: true
  - access_control: true
```

#### MAC-003: launchd Service Management
```yaml
archetype_id: "MAC-003"
name: "launchd Service Management"
category: "macos_correctness"
description: "Validates launchd integration and service lifecycle"

test_requirements:
  - plist_valid: true
  - service_lifecycle: true
  - error_recovery: true

validation_criteria:
  - plist_loads_successfully: true
  - service_starts_automatically: true
  - service_stops_cleanly: true
  - respects_run_at_load: true

service_locations:
  - user_agents: "~/Library/LaunchAgents"
  - label: "com.velocidex.velociraptor"
```

#### MAC-004: macOS UI Lifecycle
```yaml
archetype_id: "MAC-004"
name: "macOS UI Lifecycle"
category: "macos_correctness"
description: "Validates proper macOS app lifecycle handling"

test_requirements:
  - window_management: true
  - app_lifecycle_events: true
  - state_restoration: true

validation_criteria:
  - handles_terminate: true
  - handles_sleep_wake: true
  - handles_logout: true
  - state_persists: true
  - windows_restore_position: true

lifecycle_events:
  - application_will_terminate: true
  - application_did_resign_active: true
  - application_will_become_active: true
  - application_will_hide: true
```

### 3. Determinism Archetypes

#### DET-001: Repeatability Validation
```yaml
archetype_id: "DET-001"
name: "Repeatability Validation"
category: "determinism"
description: "Ensures tests produce consistent results across runs"

test_requirements:
  - multiple_runs: 3
  - stability_threshold: 0.95
  - timing_independent: true

validation_criteria:
  - consistent_results: true
  - no_random_failures: true
  - no_timing_dependencies: true
  - no_race_conditions: true

flakiness_sources:
  - timing: check
  - random_data: check
  - network: check
  - environment_state: check
```

#### DET-002: Concurrency Safety
```yaml
archetype_id: "DET-002"
name: "Concurrency Safety"
category: "determinism"
description: "Validates Swift concurrency is used correctly"

test_requirements:
  - async_await_usage: true
  - actor_isolation: true
  - sendable_conformance: true

validation_criteria:
  - no_data_races: true
  - proper_actor_isolation: true
  - ui_on_main_actor: true
  - background_tasks_isolated: true

swift_concurrency_checks:
  - main_actor_enforcement: true
  - task_cancellation_handled: true
  - structured_concurrency: true
```

### 4. Accessibility Archetypes

#### ACC-001: Accessibility Identifier Coverage
```yaml
archetype_id: "ACC-001"
name: "Accessibility Identifier Coverage"
category: "accessibility"
description: "Validates all UI elements have accessibility identifiers"

test_requirements:
  - identifier_coverage: 100%
  - identifier_uniqueness: true
  - identifier_consistency: true

validation_criteria:
  - all_buttons_identified: true
  - all_fields_identified: true
  - all_labels_identified: true
  - identifiers_match_tests: true

naming_convention:
  - format: "module.component.element"
  - examples:
    - "wizard.step.welcome"
    - "auth.field.password"
    - "navigation.button.next"
```

#### ACC-002: VoiceOver Navigation
```yaml
archetype_id: "ACC-002"
name: "VoiceOver Navigation"
category: "accessibility"
description: "Validates VoiceOver can navigate the entire app"

test_requirements:
  - voiceover_enabled: true
  - keyboard_navigation: true
  - focus_order: logical

validation_criteria:
  - all_elements_announced: true
  - labels_descriptive: true
  - hints_provided: true
  - focus_order_logical: true

accessibility_features:
  - voiceover: true
  - full_keyboard_access: true
  - reduced_motion: true
  - increase_contrast: true
```

### 5. Performance Archetypes

#### PERF-001: Response Time Validation
```yaml
archetype_id: "PERF-001"
name: "Response Time Validation"
category: "performance"
description: "Validates UI remains responsive"

test_requirements:
  - response_time_measured: true
  - baseline_established: true
  - regression_detected: true

validation_criteria:
  - app_launch_time: "< 2s"
  - step_navigation: "< 100ms"
  - config_generation: "< 5s"
  - network_download: "> 1MB/s"

performance_targets:
  - memory_idle: "< 100MB"
  - memory_active: "< 200MB"
  - cpu_idle: "< 5%"
  - cpu_active: "< 30%"
```

### 6. Security Archetypes

#### SEC-001: Credential Security
```yaml
archetype_id: "SEC-001"
name: "Credential Security"
category: "security"
description: "Validates credentials are stored and handled securely"

test_requirements:
  - keychain_storage: true
  - no_plaintext_storage: true
  - memory_scrubbing: true

validation_criteria:
  - passwords_in_keychain: true
  - no_passwords_in_logs: true
  - no_passwords_in_memory_dumps: true
  - secure_erase_on_delete: true

security_checks:
  - encryption_at_rest: true
  - secure_transmission: true
  - proper_permissions: true
  - code_signing: true
```

## Usage

### For Gap Validation

When validating a gap, select appropriate archetypes:

```swift
let testingAgent = TestingAgent()

// Validate GAP-003: Accessibility Identifiers
let result = try await testingAgent.validateGap(
    gapID: "GAP-003",
    description: "Accessibility Identifiers Not Applied",
    testCategories: [.functional, .accessibility, .determinism]
)

// The agent will apply:
// - FC-002: UI Flow Validation
// - ACC-001: Accessibility Identifier Coverage
// - ACC-002: VoiceOver Navigation
// - DET-001: Repeatability Validation
```

### For CDIF Report Generation

```swift
let reporter = TestReporter()
let cdifReport = reporter.generateReport(results, format: .cdif)
```

## Archetype Extension

To add new archetypes:

1. Define the archetype in YAML format
2. Document test requirements
3. Specify validation criteria
4. Add to appropriate category
5. Update this catalog
6. Implement test logic in TestingAgent

## Path Reference Index (Workspace)

After workspace reorganization, **all** canonical paths. Code and docs must reference these; do not assume root-level scripts or modules.

### KB discovery (CDIF / Steering)

| Reference | Path (from repo root) | Notes |
|-----------|------------------------|-------|
| **CDIF / Steering KB index** | `steering/CDIF_KB_INDEX.md` | Canonical entrypoint + search exclusions |
| **KB manifest (machine-readable)** | `steering/CDIF_KB_MANIFEST.yaml` | YAML manifest of KB roots, exclusions, and doc IDs |
| **Workspace path index** | `docs/WORKSPACE_PATH_INDEX.md` | Single source of truth for paths |

**Search exclusions (critical)**:

- Ignore vendor/build trees when searching the KB: `**/node_modules/**`, `.build/`, `.swiftpm/`, `DerivedData/`
- Ignore ephemeral run output: `tests/results/` (**do not commit**; use CI artifacts or link in GitHub issues)

### CDIF and path resolution

| Reference | Path (from repo root) |
|-----------|------------------------|
| **CDIF catalog (this file)** | `apps/macos-app/CDIF_TEST_ARCHETYPES.md` |
| **Workspace path index** | `docs/WORKSPACE_PATH_INDEX.md` |
| **CDIF parent/child registry** | `.claude/agents/MACOS_SDLC_AGENT_PROMPTS.md` (CDIF-ARCH-*, CDIF-IMPL-*) |

### PowerShell deployment and module

| Reference | Path (from repo root) |
|-----------|------------------------|
| **Deployment scripts** | `scripts/Deploy_Velociraptor_Standalone.ps1`, `scripts/Deploy_Velociraptor_Server.ps1` |
| **PowerShell root module** | `lib/VelociraptorSetupScripts.psd1`, `lib/VelociraptorSetupScripts.psm1` |
| **Deployment module** | `lib/modules/VelociraptorDeployment/VelociraptorDeployment.psd1` |
| **GUI (canonical)** | `apps/gui/VelociraptorGUI.ps1` |

### macOS app and steering

| Reference | Path (from repo root) |
|-----------|------------------------|
| **macOS app (canonical build + tests)** | `apps/macos-app/VelociraptorMacOS/` (app + TestingAgent) |
| **macOS unit tests (Swift)** | `apps/macos-app/VelociraptorMacOSTests/` |
| **macOS UI tests (Swift)** | `apps/macos-app/VelociraptorMacOSUITests/` |
| **macOS app (root snapshot / lightweight copy)** | `VelociraptorMacOS/` (not the SPM/Xcodegen canonical build) |
| **Gap registry (hex)** | `Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md` |
| **macOS implementation guide** | `Velociraptor_macOS_App/steering/MACOS-IMPLEMENTATION-GUIDE.md`, `steering/macos-app/macOS-Implementation-Guide.md` |
| **macOS code review** | `steering/MACOS_CODE_REVIEW_ANALYSIS.md` |

### Steering, gap, and iteration

| Reference | Path (from repo root) |
|-----------|------------------------|
| **Steering (main)** | `steering/` (structure.md, tech.md, product.md, MACOS_*.md, p0/p1-*.md) |
| **Steering (kiro)** | `.kiro/steering/` (product.md, structure.md, tech.md) |
| **Gap analysis docs** | `docs/GAP-ANALYSIS-EXECUTIVE-SUMMARY.md`, `docs/MASSIVE-GAP-ANALYSIS-MACOS-VS-ELECTRON-2026-01-31.md`, `docs/GAP-ANALYSIS-TO-IMPLEMENTATION-COMPLETE.md` |
| **Delivery summary** | `docs/FINAL-DELIVERY-SUMMARY.md` |

### Documentation and agents

| Reference | Path (from repo root) |
|-----------|------------------------|
| **Documentation** | `docs/` (all project docs; no loose .md at root) |
| **Agent prompts (macOS SDLC)** | `.claude/agents/MACOS_SDLC_AGENT_PROMPTS.md` |
| **Agent index** | `.claude/agents/README.md` |
| **GitHub agents** | `.github/agents/` (macos-development-agent.md, etc.) |

### Tests, build, cloud, tools

| Reference | Path (from repo root) |
|-----------|------------------------|
| **Unit tests** | `tests/unit/` |
| **Integration tests** | `tests/integration/` |
| **Security tests** | `tests/security/` |
| **Test runner** | `tests/Run-Tests.ps1` |
| **Test artifacts (generated, gitignored)** | `tests/results/` (local/CI artifacts; link from issues) |
| **Build / release assets** | `build/` |
| **Cloud** | `cloud/aws/`, `cloud/azure/` |
| **Containers** | `containers/docker/`, `containers/kubernetes/` |
| **Incident packages** | `tools/incident-packages/` |

Use `docs/WORKSPACE_PATH_INDEX.md` for the full list and for updating code that references moved files.

## References

- [CDIF / Steering KB Index](../../steering/CDIF_KB_INDEX.md)
- [macOS QA/UA Testing Plan](../../steering/MACOS_QA_TEST_PLAN.md)
- [Gap Analysis Documentation](../../steering/MACOS_GAP_ANALYSIS_ITERATION_2.md)
- [Gap Registry (hex)](../../Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md)
- [Testing Agent Documentation](VelociraptorMacOS/TestingAgent/README.md) (within macos-app)
- [Workspace Path Index](../../docs/WORKSPACE_PATH_INDEX.md) — **read first** for path resolution
