# CDIF Test Archetypes Catalog

## Overview

This catalog defines Common Definition of Issue Format (CDIF) test archetypes for the macOS Testing Agent. Each archetype represents a reusable test pattern for validating gap closure.

## Schema Version

**Version:** 1.0
**Last Updated:** 2026-01-30

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

## References

- [macOS HiQ Testing Requirements](MACOS_QA_TEST_PLAN.md)
- [Gap Analysis Documentation](steering/MACOS_GAP_ANALYSIS_ITERATION_2.md)
- [Testing Agent Documentation](TestingAgent/README.md)
