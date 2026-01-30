# Foreman Agent Gap Analysis & Orchestration (macOS)

This document applies the **Foreman Agent** prompt to the current repository state to establish an authoritative macOS gap registry and a first-pass orchestration plan.

## Phase 1 — Gap Analysis (Authoritative Truth)

### Gap Registry

| Gap ID | Severity | Gap Description | Closure Criteria | Verification Steps | CDIF/CEDIF Child-Object Update | MCP Task Payload Stub |
| --- | --- | --- | --- | --- | --- | --- |
| MACOS-GAP-001 | P0 | No Xcode project or macOS app target present in the repository; there is no macOS build artifact or project structure to compile. | Add an Xcode project with at least one macOS app target, buildable in Xcode. | Open the Xcode project and build the macOS app target in Debug configuration. | Add `cdif.project.xcode` child object referencing the new `.xcodeproj` path and targets. | `{"gap_id":"MACOS-GAP-001","task":"Create Xcode project + macOS app target","expected_artifacts":["*.xcodeproj","App target"],"verification":"xcodebuild -scheme <scheme> build"}` |
| MACOS-GAP-002 | P1 | No Swift 6 / SwiftUI source tree exists; no UI layer defined for macOS. | Add initial Swift 6 + SwiftUI app scaffold with a basic window scene. | Build and run app to confirm window renders. | Add `cdif.ui.swiftui` child object pointing to new SwiftUI entry point. | `{"gap_id":"MACOS-GAP-002","task":"Add SwiftUI app scaffold","expected_artifacts":["App.swift","ContentView.swift"],"verification":"xcodebuild -scheme <scheme> build"}` |
| MACOS-GAP-003 | P1 | No accessibility identifiers present for UI automation; no UI testability baseline. | Add accessibility identifiers for primary UI controls. | Run UI test to query identifiers. | Add `cdif.ui.accessibility` child object listing identifiers. | `{"gap_id":"MACOS-GAP-003","task":"Add accessibility identifiers","expected_artifacts":["Accessibility identifiers"],"verification":"UI test queries identifiers"}` |
| MACOS-GAP-004 | P2 | No App Sandbox entitlements or Hardened Runtime configuration tracked for macOS app. | Define entitlements file and document required sandbox scopes. | Inspect entitlements in Xcode; confirm minimal access. | Add `cdif.security.entitlements` child object referencing entitlements file. | `{"gap_id":"MACOS-GAP-004","task":"Define entitlements + sandbox scope","expected_artifacts":["*.entitlements"],"verification":"Xcode build + entitlement review"}` |
| MACOS-GAP-005 | P2 | No Apple Intelligence / AI boundaries or cloud AI gating documented. | Provide explicit AI boundary policy and gating toggles. | Review documentation and ensure no unguarded outbound AI usage. | Add `cdif.ai.boundaries` child object referencing policy. | `{"gap_id":"MACOS-GAP-005","task":"Document AI boundary policy","expected_artifacts":["AI policy doc"],"verification":"Doc review"}` |

## Phase 2 — Master Iteration Document

1. **Create baseline macOS Xcode project**
   - Target files: new `.xcodeproj`, `Sources/` directory.
   - Dependency notes: None.
   - Status pipeline: Implemented → Tested → QA → UAT → Platform QA → Security → Prod.
2. **Add Swift 6 + SwiftUI app scaffold**
   - Target files: `App.swift`, `ContentView.swift`.
   - Dependency notes: Requires gap MACOS-GAP-001.
   - Status pipeline: Implemented → Tested → QA → UAT → Platform QA → Security → Prod.
3. **Add baseline accessibility identifiers**
   - Target files: `ContentView.swift` (or equivalent).
   - Dependency notes: Requires gap MACOS-GAP-002.
   - Status pipeline: Implemented → Tested → QA → UAT → Platform QA → Security → Prod.
4. **Define entitlements + sandbox scope**
   - Target files: `*.entitlements`, build settings.
   - Dependency notes: Requires gap MACOS-GAP-001.
   - Status pipeline: Implemented → Tested → QA → UAT → Platform QA → Security → Prod.
5. **Document AI boundary policy**
   - Target files: `docs/` policy doc.
   - Dependency notes: None.
   - Status pipeline: Implemented → Tested → QA → UAT → Platform QA → Security → Prod.

## Phase 3 — Swarm Dispatch Plan

- **Dev Agent**: MACOS-GAP-001 — Create Xcode project and macOS app target.
  - Expected outputs: `*.xcodeproj`, buildable target.
  - Verification: `xcodebuild -scheme <scheme> build`.
- **Dev Agent**: MACOS-GAP-002 — SwiftUI scaffold.
  - Expected outputs: `App.swift`, `ContentView.swift`.
  - Verification: build + run.
- **Dev Agent**: MACOS-GAP-003 — Accessibility identifiers.
  - Expected outputs: stable identifiers on primary UI elements.
  - Verification: UI test query.
- **Dev Agent**: MACOS-GAP-004 — Entitlements.
  - Expected outputs: `*.entitlements`, minimal sandbox scopes.
  - Verification: build + entitlement review.
- **Dev Agent**: MACOS-GAP-005 — AI boundary policy.
  - Expected outputs: documentation in `docs/`.
  - Verification: review doc, ensure gating.

## Phase 4 — Phase-Gated Closure

Each gap proceeds through: Dev → Test → QA → UAT → Platform QA → Security → Production. After closure, update CDIF entries with implementation details and add verification evidence.
