#!/bin/bash
# Gap Analysis Execution Script
# Velociraptor Claw Edition - macOS
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
APP_SOURCE="${REPO_ROOT}/apps/macos-legacy/VelociraptorMacOS"
GAP_REGISTRY="${REPO_ROOT}/Velociraptor_macOS_App/steering/HEXADECIMAL-GAP-REGISTRY.md"
OUTPUT_DIR="${REPO_ROOT}/.claude/agents/analysis-output"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        VELOCIRAPTOR CLAW EDITION - GAP ANALYSIS              ║${NC}"
echo -e "${BLUE}║              macOS Native App Audit                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create output directory
mkdir -p "${OUTPUT_DIR}/${TIMESTAMP}"
OUTPUT="${OUTPUT_DIR}/${TIMESTAMP}"

echo -e "${YELLOW}📋 Gap Analysis Started: $(date)${NC}"
echo ""

# ============================================================================
# SECTION 1: CODE STRUCTURE AUDIT
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SECTION 1: CODE STRUCTURE AUDIT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check for critical missing files
echo -e "\n${YELLOW}Checking for critical API/Service files...${NC}"

CRITICAL_MISSING=()
CRITICAL_FILES=(
    "Services/VelociraptorAPIClient.swift"
    "Services/WebSocketService.swift"
    "Views/ClientsView.swift"
    "Views/HuntManagerView.swift"
    "Views/VQLEditorView.swift"
    "Views/DashboardView.swift"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "${APP_SOURCE}/${file}" ]; then
        echo -e "  ${RED}✗ MISSING:${NC} ${file}"
        CRITICAL_MISSING+=("${file}")
    else
        echo -e "  ${GREEN}✓ EXISTS:${NC} ${file}"
    fi
done

echo "${#CRITICAL_MISSING[@]} critical files missing" > "${OUTPUT}/critical-missing.txt"
printf '%s\n' "${CRITICAL_MISSING[@]}" >> "${OUTPUT}/critical-missing.txt"

# ============================================================================
# SECTION 2: ACCESSIBILITY AUDIT
# ============================================================================

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SECTION 2: ACCESSIBILITY IDENTIFIER AUDIT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Count accessibility identifiers
if [ -d "${APP_SOURCE}/Views" ]; then
    TOTAL_CONTROLS=$(grep -rE "Button|TextField|Picker|Toggle|SecureField|TextEditor" "${APP_SOURCE}/Views/" 2>/dev/null | wc -l | tr -d ' ')
    CONTROLS_WITH_IDS=$(grep -r "accessibilityIdentifier" "${APP_SOURCE}/Views/" 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$TOTAL_CONTROLS" -gt 0 ]; then
        COVERAGE=$((CONTROLS_WITH_IDS * 100 / TOTAL_CONTROLS))
    else
        COVERAGE=0
    fi
    
    echo -e "\n  Total interactive controls: ${TOTAL_CONTROLS}"
    echo -e "  Controls with accessibility IDs: ${CONTROLS_WITH_IDS}"
    echo -e "  Coverage: ${COVERAGE}%"
    
    if [ "$COVERAGE" -lt 90 ]; then
        echo -e "  ${RED}⚠️  Coverage below 90% threshold${NC}"
    else
        echo -e "  ${GREEN}✓ Coverage meets threshold${NC}"
    fi
    
    echo "total_controls: ${TOTAL_CONTROLS}" > "${OUTPUT}/accessibility-audit.yaml"
    echo "controls_with_ids: ${CONTROLS_WITH_IDS}" >> "${OUTPUT}/accessibility-audit.yaml"
    echo "coverage_percent: ${COVERAGE}" >> "${OUTPUT}/accessibility-audit.yaml"
else
    echo -e "  ${RED}✗ Views directory not found${NC}"
fi

# ============================================================================
# SECTION 3: SWIFT CONCURRENCY AUDIT
# ============================================================================

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SECTION 3: SWIFT CONCURRENCY AUDIT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -d "${APP_SOURCE}" ]; then
    # Check for @MainActor usage
    MAINACTOR_COUNT=$(grep -r "@MainActor" "${APP_SOURCE}/" 2>/dev/null | wc -l | tr -d ' ')
    
    # Check for actor declarations
    ACTOR_COUNT=$(grep -r "^actor\|^final actor\|^public actor" "${APP_SOURCE}/" 2>/dev/null | wc -l | tr -d ' ')
    
    # Check for async/await usage
    ASYNC_COUNT=$(grep -r "async\|await" "${APP_SOURCE}/" 2>/dev/null | wc -l | tr -d ' ')
    
    # Check for potential issues (DispatchQueue on main thread in Views)
    DISPATCH_IN_VIEWS=$(grep -r "DispatchQueue.main" "${APP_SOURCE}/Views/" 2>/dev/null | wc -l | tr -d ' ')
    
    echo -e "\n  @MainActor annotations: ${MAINACTOR_COUNT}"
    echo -e "  Actor declarations: ${ACTOR_COUNT}"
    echo -e "  async/await usages: ${ASYNC_COUNT}"
    echo -e "  DispatchQueue.main in Views: ${DISPATCH_IN_VIEWS}"
    
    if [ "$DISPATCH_IN_VIEWS" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠️  Found DispatchQueue.main in Views (prefer @MainActor)${NC}"
    fi
    
    echo "mainactor_count: ${MAINACTOR_COUNT}" > "${OUTPUT}/concurrency-audit.yaml"
    echo "actor_count: ${ACTOR_COUNT}" >> "${OUTPUT}/concurrency-audit.yaml"
    echo "async_await_count: ${ASYNC_COUNT}" >> "${OUTPUT}/concurrency-audit.yaml"
    echo "dispatchqueue_in_views: ${DISPATCH_IN_VIEWS}" >> "${OUTPUT}/concurrency-audit.yaml"
fi

# ============================================================================
# SECTION 4: BUILD VALIDATION
# ============================================================================

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SECTION 4: BUILD VALIDATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -f "${REPO_ROOT}/apps/macos-legacy/Package.swift" ]; then
    echo -e "\n  Running swift build..."
    cd "${REPO_ROOT}/apps/macos-legacy"
    
    if swift build 2>&1 | tee "${OUTPUT}/build-output.log"; then
        echo -e "  ${GREEN}✓ Build succeeded${NC}"
        echo "build_status: SUCCESS" > "${OUTPUT}/build-status.yaml"
    else
        echo -e "  ${RED}✗ Build failed${NC}"
        echo "build_status: FAILED" > "${OUTPUT}/build-status.yaml"
    fi
    
    cd "${REPO_ROOT}"
else
    echo -e "  ${RED}✗ Package.swift not found${NC}"
fi

# ============================================================================
# SECTION 5: TEST COVERAGE
# ============================================================================

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SECTION 5: TEST COVERAGE AUDIT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

UNIT_TESTS_DIR="${REPO_ROOT}/apps/macos-legacy/VelociraptorMacOSTests"
UI_TESTS_DIR="${REPO_ROOT}/apps/macos-legacy/VelociraptorMacOSUITests"

if [ -d "${UNIT_TESTS_DIR}" ]; then
    UNIT_TEST_COUNT=$(find "${UNIT_TESTS_DIR}" -name "*.swift" | wc -l | tr -d ' ')
    UNIT_TEST_FUNCS=$(grep -r "func test" "${UNIT_TESTS_DIR}/" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "\n  Unit test files: ${UNIT_TEST_COUNT}"
    echo -e "  Unit test functions: ${UNIT_TEST_FUNCS}"
else
    UNIT_TEST_COUNT=0
    UNIT_TEST_FUNCS=0
    echo -e "\n  ${RED}✗ Unit tests directory not found${NC}"
fi

if [ -d "${UI_TESTS_DIR}" ]; then
    UI_TEST_COUNT=$(find "${UI_TESTS_DIR}" -name "*.swift" | wc -l | tr -d ' ')
    UI_TEST_FUNCS=$(grep -r "func test" "${UI_TESTS_DIR}/" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  UI test files: ${UI_TEST_COUNT}"
    echo -e "  UI test functions: ${UI_TEST_FUNCS}"
else
    UI_TEST_COUNT=0
    UI_TEST_FUNCS=0
    echo -e "  ${RED}✗ UI tests directory not found${NC}"
fi

cat > "${OUTPUT}/test-coverage.yaml" << EOF
unit_tests:
  files: ${UNIT_TEST_COUNT}
  functions: ${UNIT_TEST_FUNCS}
ui_tests:
  files: ${UI_TEST_COUNT}
  functions: ${UI_TEST_FUNCS}
total_test_functions: $((UNIT_TEST_FUNCS + UI_TEST_FUNCS))
EOF

# ============================================================================
# SECTION 6: ENTITLEMENTS AUDIT
# ============================================================================

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SECTION 6: ENTITLEMENTS & SANDBOX AUDIT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

ENTITLEMENTS="${APP_SOURCE}/VelociraptorMacOS.entitlements"

if [ -f "${ENTITLEMENTS}" ]; then
    echo -e "\n  Entitlements file found"
    
    # Check for sandbox
    if grep -q "com.apple.security.app-sandbox" "${ENTITLEMENTS}"; then
        echo -e "  ${GREEN}✓ App Sandbox enabled${NC}"
    else
        echo -e "  ${RED}✗ App Sandbox NOT enabled${NC}"
    fi
    
    # Check for temporary exceptions
    TEMP_EXCEPTIONS=$(grep -c "temporary-exception" "${ENTITLEMENTS}" 2>/dev/null || echo "0")
    if [ "$TEMP_EXCEPTIONS" -gt 0 ]; then
        echo -e "  ${RED}⚠️  ${TEMP_EXCEPTIONS} temporary exceptions found${NC}"
    else
        echo -e "  ${GREEN}✓ No temporary exceptions${NC}"
    fi
    
    cp "${ENTITLEMENTS}" "${OUTPUT}/entitlements.plist"
    echo "entitlements_file: exists" > "${OUTPUT}/entitlements-audit.yaml"
    echo "temporary_exceptions: ${TEMP_EXCEPTIONS}" >> "${OUTPUT}/entitlements-audit.yaml"
else
    echo -e "  ${RED}✗ Entitlements file not found${NC}"
    echo "entitlements_file: missing" > "${OUTPUT}/entitlements-audit.yaml"
fi

# ============================================================================
# SECTION 7: GAP SUMMARY GENERATION
# ============================================================================

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SECTION 7: GAP SUMMARY${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Generate gap summary
cat > "${OUTPUT}/gap-summary.yaml" << EOF
# Gap Analysis Summary
# Generated: $(date -Iseconds)

metadata:
  timestamp: "$(date -Iseconds)"
  repository: "${REPO_ROOT}"
  analyzer: "gap-analysis-script-v1.0"

summary:
  critical_files_missing: ${#CRITICAL_MISSING[@]}
  accessibility_coverage: ${COVERAGE:-0}%
  build_status: "$(cat "${OUTPUT}/build-status.yaml" 2>/dev/null | grep build_status | cut -d: -f2 | tr -d ' ')"
  total_test_functions: $((UNIT_TEST_FUNCS + UI_TEST_FUNCS))

gaps:
  P0_critical:
    - id: "0x01"
      title: "Velociraptor API Client Missing"
      status: "$([ -f "${APP_SOURCE}/Services/VelociraptorAPIClient.swift" ] && echo "CLOSED" || echo "OPEN")"
    - id: "0x02"
      title: "Client Management Interface Missing"
      status: "$([ -f "${APP_SOURCE}/Views/ClientsView.swift" ] && echo "CLOSED" || echo "OPEN")"
    - id: "0x03"
      title: "Hunt Management Interface Missing"
      status: "$([ -f "${APP_SOURCE}/Views/HuntManagerView.swift" ] && echo "CLOSED" || echo "OPEN")"
    - id: "0x04"
      title: "VQL Terminal Missing"
      status: "$([ -f "${APP_SOURCE}/Views/VQLEditorView.swift" ] && echo "CLOSED" || echo "OPEN")"
    - id: "0x05"
      title: "Dashboard with Widgets Missing"
      status: "$([ -f "${APP_SOURCE}/Views/DashboardView.swift" ] && echo "CLOSED" || echo "OPEN")"
    - id: "0x09"
      title: "Accessibility Identifiers Missing"
      status: "$([ "${COVERAGE:-0}" -ge 90 ] && echo "CLOSED" || echo "OPEN")"

  P1_high:
    - id: "0x06"
      title: "VFS Browser Missing"
      status: "OPEN"
    - id: "0x07"
      title: "DFIR Tools Integration Missing"
      status: "OPEN"
    - id: "0x08"
      title: "WebSocket Real-Time Missing"
      status: "$([ -f "${APP_SOURCE}/Services/WebSocketService.swift" ] && echo "CLOSED" || echo "OPEN")"
EOF

# ============================================================================
# FINAL REPORT
# ============================================================================

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}GAP ANALYSIS COMPLETE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${GREEN}📊 RESULTS SUMMARY${NC}"
echo -e "  Critical files missing: ${RED}${#CRITICAL_MISSING[@]}${NC}"
echo -e "  Accessibility coverage: ${COVERAGE:-0}%"
echo -e "  Total test functions: $((UNIT_TEST_FUNCS + UI_TEST_FUNCS))"

echo -e "\n${YELLOW}📁 Output saved to: ${OUTPUT}${NC}"
ls -la "${OUTPUT}"

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Gap Analysis Complete - $(date)          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
