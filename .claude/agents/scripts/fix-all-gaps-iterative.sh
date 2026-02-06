#!/bin/bash
# Fix-All-Gaps Iterative Execution Script
# Velociraptor Claw Edition - macOS
# Version: 1.0.0
#
# This script implements the Master Iteration Framework:
# 1. Run Gap Analysis
# 2. Generate Master Iteration Document
# 3. Execute tasks in dependency order
# 4. Verify closure at each gate
# 5. Update CDIF and MCP
# 6. Repeat until convergence

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SCRIPTS_DIR="${REPO_ROOT}/.claude/agents/scripts"
OUTPUT_DIR="${REPO_ROOT}/.claude/agents/iteration-output"
MAX_ITERATIONS="${MAX_ITERATIONS:-10}"
SCOPE="${SCOPE:-mvp}"  # mvp or full
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
ITERATION_DIR="${OUTPUT_DIR}/${TIMESTAMP}"

# Create output directory
mkdir -p "${ITERATION_DIR}"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_header() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
}

log_section() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

log_info() {
    echo -e "${PURPLE}ℹ $1${NC}"
}

# ============================================================================
# PHASE 0: INITIALIZATION
# ============================================================================

log_header "MASTER ITERATION FRAMEWORK - FIX ALL GAPS"
echo -e "  Repository: ${REPO_ROOT}"
echo -e "  Scope: ${SCOPE}"
echo -e "  Max Iterations: ${MAX_ITERATIONS}"
echo -e "  Output: ${ITERATION_DIR}"
echo -e "  Started: $(date)"

# Define MVP gaps
if [ "${SCOPE}" = "mvp" ]; then
    GAPS_TO_CLOSE=("0x01" "0x02" "0x03" "0x04" "0x05" "0x09")
    log_info "MVP Scope: ${#GAPS_TO_CLOSE[@]} P0 gaps targeted"
else
    GAPS_TO_CLOSE=("0x01" "0x02" "0x03" "0x04" "0x05" "0x06" "0x07" "0x08" "0x09" "0x0A" "0x0B" "0x0C" "0x0D" "0x0E" "0x0F" "0x10" "0x11" "0x12")
    log_info "Full Scope: ${#GAPS_TO_CLOSE[@]} total gaps targeted"
fi

# ============================================================================
# PHASE 1: RUN GAP ANALYSIS
# ============================================================================

run_gap_analysis() {
    local iteration=$1
    log_section "ITERATION ${iteration}: GAP ANALYSIS"
    
    local analysis_dir="${ITERATION_DIR}/iteration-${iteration}/gap-analysis"
    mkdir -p "${analysis_dir}"
    
    # Run the gap analysis script
    if [ -f "${SCRIPTS_DIR}/run-gap-analysis.sh" ]; then
        REPO_ROOT="${REPO_ROOT}" bash "${SCRIPTS_DIR}/run-gap-analysis.sh" 2>&1 | tee "${analysis_dir}/analysis.log"
    else
        log_warning "Gap analysis script not found, running inline analysis..."
        
        # Inline gap check
        APP_SOURCE="${REPO_ROOT}/apps/macos-legacy/VelociraptorMacOS"
        
        for gap in "${GAPS_TO_CLOSE[@]}"; do
            case "${gap}" in
                "0x01")
                    if [ -f "${APP_SOURCE}/Services/VelociraptorAPIClient.swift" ]; then
                        echo "0x01:CLOSED" >> "${analysis_dir}/gap-status.txt"
                    else
                        echo "0x01:OPEN" >> "${analysis_dir}/gap-status.txt"
                    fi
                    ;;
                "0x02")
                    if [ -f "${APP_SOURCE}/Views/ClientsView.swift" ]; then
                        echo "0x02:CLOSED" >> "${analysis_dir}/gap-status.txt"
                    else
                        echo "0x02:OPEN" >> "${analysis_dir}/gap-status.txt"
                    fi
                    ;;
                "0x03")
                    if [ -f "${APP_SOURCE}/Views/HuntManagerView.swift" ]; then
                        echo "0x03:CLOSED" >> "${analysis_dir}/gap-status.txt"
                    else
                        echo "0x03:OPEN" >> "${analysis_dir}/gap-status.txt"
                    fi
                    ;;
                "0x04")
                    if [ -f "${APP_SOURCE}/Views/VQLEditorView.swift" ]; then
                        echo "0x04:CLOSED" >> "${analysis_dir}/gap-status.txt"
                    else
                        echo "0x04:OPEN" >> "${analysis_dir}/gap-status.txt"
                    fi
                    ;;
                "0x05")
                    if [ -f "${APP_SOURCE}/Views/DashboardView.swift" ]; then
                        echo "0x05:CLOSED" >> "${analysis_dir}/gap-status.txt"
                    else
                        echo "0x05:OPEN" >> "${analysis_dir}/gap-status.txt"
                    fi
                    ;;
                "0x08")
                    if [ -f "${APP_SOURCE}/Services/WebSocketService.swift" ]; then
                        echo "0x08:CLOSED" >> "${analysis_dir}/gap-status.txt"
                    else
                        echo "0x08:OPEN" >> "${analysis_dir}/gap-status.txt"
                    fi
                    ;;
                "0x09")
                    # Check accessibility coverage
                    if [ -d "${APP_SOURCE}/Views" ]; then
                        TOTAL=$(grep -rE "Button|TextField|Picker|Toggle" "${APP_SOURCE}/Views/" 2>/dev/null | wc -l | tr -d ' ')
                        WITH_IDS=$(grep -r "accessibilityIdentifier" "${APP_SOURCE}/Views/" 2>/dev/null | wc -l | tr -d ' ')
                        if [ "$TOTAL" -gt 0 ] && [ $((WITH_IDS * 100 / TOTAL)) -ge 90 ]; then
                            echo "0x09:CLOSED" >> "${analysis_dir}/gap-status.txt"
                        else
                            echo "0x09:OPEN" >> "${analysis_dir}/gap-status.txt"
                        fi
                    else
                        echo "0x09:OPEN" >> "${analysis_dir}/gap-status.txt"
                    fi
                    ;;
                *)
                    echo "${gap}:OPEN" >> "${analysis_dir}/gap-status.txt"
                    ;;
            esac
        done
    fi
    
    # Count open gaps
    OPEN_GAPS=$(grep -c ":OPEN" "${analysis_dir}/gap-status.txt" 2>/dev/null || echo "0")
    CLOSED_GAPS=$(grep -c ":CLOSED" "${analysis_dir}/gap-status.txt" 2>/dev/null || echo "0")
    
    log_info "Open gaps: ${OPEN_GAPS}"
    log_info "Closed gaps: ${CLOSED_GAPS}"
    
    echo "${OPEN_GAPS}" > "${analysis_dir}/open-count.txt"
    
    return "${OPEN_GAPS}"
}

# ============================================================================
# PHASE 2: GENERATE MASTER ITERATION DOCUMENT
# ============================================================================

generate_master_document() {
    local iteration=$1
    log_section "ITERATION ${iteration}: GENERATING MASTER DOCUMENT"
    
    local doc_dir="${ITERATION_DIR}/iteration-${iteration}/master-document"
    mkdir -p "${doc_dir}"
    
    local analysis_dir="${ITERATION_DIR}/iteration-${iteration}/gap-analysis"
    
    cat > "${doc_dir}/MASTER_ITERATION.md" << 'HEADER'
# Master Iteration Document

## Generated by Fix-All-Gaps Iterative Framework

HEADER

    echo "**Iteration**: ${iteration}" >> "${doc_dir}/MASTER_ITERATION.md"
    echo "**Generated**: $(date -Iseconds)" >> "${doc_dir}/MASTER_ITERATION.md"
    echo "" >> "${doc_dir}/MASTER_ITERATION.md"
    
    echo "## Gap Status" >> "${doc_dir}/MASTER_ITERATION.md"
    echo "" >> "${doc_dir}/MASTER_ITERATION.md"
    echo "| Gap ID | Title | Status | Priority |" >> "${doc_dir}/MASTER_ITERATION.md"
    echo "|--------|-------|--------|----------|" >> "${doc_dir}/MASTER_ITERATION.md"
    
    # Read gap status and generate table
    while IFS=: read -r gap status; do
        case "${gap}" in
            "0x01") title="Velociraptor API Client"; priority="P0" ;;
            "0x02") title="Client Management Interface"; priority="P0" ;;
            "0x03") title="Hunt Management Interface"; priority="P0" ;;
            "0x04") title="VQL Terminal"; priority="P0" ;;
            "0x05") title="Dashboard with Widgets"; priority="P0" ;;
            "0x06") title="VFS Browser"; priority="P1" ;;
            "0x07") title="DFIR Tools Integration"; priority="P1" ;;
            "0x08") title="WebSocket Real-Time"; priority="P1" ;;
            "0x09") title="Accessibility Identifiers"; priority="P0" ;;
            *) title="Unknown Gap"; priority="P2" ;;
        esac
        
        if [ "${status}" = "OPEN" ]; then
            status_icon="🔴 OPEN"
        else
            status_icon="🟢 CLOSED"
        fi
        
        echo "| ${gap} | ${title} | ${status_icon} | ${priority} |" >> "${doc_dir}/MASTER_ITERATION.md"
    done < "${analysis_dir}/gap-status.txt"
    
    echo "" >> "${doc_dir}/MASTER_ITERATION.md"
    echo "## Task Queue (Open Gaps)" >> "${doc_dir}/MASTER_ITERATION.md"
    echo "" >> "${doc_dir}/MASTER_ITERATION.md"
    
    # Generate task list for open gaps
    local task_num=1
    while IFS=: read -r gap status; do
        if [ "${status}" = "OPEN" ]; then
            echo "### Task ${task_num}: ${gap}" >> "${doc_dir}/MASTER_ITERATION.md"
            echo "" >> "${doc_dir}/MASTER_ITERATION.md"
            echo "**Agent**: development-agent" >> "${doc_dir}/MASTER_ITERATION.md"
            echo "**Status**: Pending" >> "${doc_dir}/MASTER_ITERATION.md"
            
            case "${gap}" in
                "0x01")
                    echo "**Action**: Implement VelociraptorAPIClient.swift" >> "${doc_dir}/MASTER_ITERATION.md"
                    echo "**Files**: Services/VelociraptorAPIClient.swift, Services/APIAuthenticationService.swift, Models/APIModels.swift" >> "${doc_dir}/MASTER_ITERATION.md"
                    ;;
                "0x02")
                    echo "**Action**: Implement ClientsView.swift" >> "${doc_dir}/MASTER_ITERATION.md"
                    echo "**Dependencies**: 0x01 (API Client)" >> "${doc_dir}/MASTER_ITERATION.md"
                    ;;
                "0x03")
                    echo "**Action**: Implement HuntManagerView.swift" >> "${doc_dir}/MASTER_ITERATION.md"
                    echo "**Dependencies**: 0x01 (API Client), 0x08 (WebSocket)" >> "${doc_dir}/MASTER_ITERATION.md"
                    ;;
                "0x04")
                    echo "**Action**: Implement VQLEditorView.swift" >> "${doc_dir}/MASTER_ITERATION.md"
                    echo "**Dependencies**: 0x01 (API Client)" >> "${doc_dir}/MASTER_ITERATION.md"
                    ;;
                "0x05")
                    echo "**Action**: Implement DashboardView.swift" >> "${doc_dir}/MASTER_ITERATION.md"
                    echo "**Dependencies**: 0x01 (API Client), 0x08 (WebSocket)" >> "${doc_dir}/MASTER_ITERATION.md"
                    ;;
                "0x08")
                    echo "**Action**: Implement WebSocketService.swift" >> "${doc_dir}/MASTER_ITERATION.md"
                    echo "**Dependencies**: 0x01 (API Client)" >> "${doc_dir}/MASTER_ITERATION.md"
                    ;;
                "0x09")
                    echo "**Action**: Add accessibility identifiers to all controls" >> "${doc_dir}/MASTER_ITERATION.md"
                    echo "**Dependencies**: None" >> "${doc_dir}/MASTER_ITERATION.md"
                    ;;
            esac
            
            echo "" >> "${doc_dir}/MASTER_ITERATION.md"
            task_num=$((task_num + 1))
        fi
    done < "${analysis_dir}/gap-status.txt"
    
    log_success "Master Iteration Document generated: ${doc_dir}/MASTER_ITERATION.md"
}

# ============================================================================
# PHASE 3: SWARM DISPATCH (Simulated)
# ============================================================================

dispatch_swarm() {
    local iteration=$1
    log_section "ITERATION ${iteration}: SWARM DISPATCH"
    
    local dispatch_dir="${ITERATION_DIR}/iteration-${iteration}/dispatch"
    mkdir -p "${dispatch_dir}"
    
    log_info "In a full implementation, this phase would:"
    echo "  1. Read the Master Iteration Document"
    echo "  2. Identify open gaps respecting dependency order"
    echo "  3. Spawn HiQ agents for each gap"
    echo "  4. Development Agent → Testing Agent → QA → UAT → Platform QA → Security"
    echo ""
    
    # Generate dispatch plan
    cat > "${dispatch_dir}/dispatch-plan.yaml" << EOF
# Swarm Dispatch Plan - Iteration ${iteration}
# Generated: $(date -Iseconds)

dispatch_waves:
  wave_1:
    description: "Foundation - API Client (blocks everything)"
    gaps: ["0x01"]
    agents: ["development-agent"]
    parallel: false
  
  wave_2:
    description: "Parallel development after API"
    gaps: ["0x05", "0x08", "0x09"]
    agents: ["development-agent"]
    parallel: true
    depends_on: ["wave_1"]
  
  wave_3:
    description: "Core workflows"
    gaps: ["0x02", "0x03", "0x04"]
    agents: ["development-agent"]
    parallel: true
    depends_on: ["wave_1"]

execution_instructions: |
  To execute this dispatch plan:
  
  1. Invoke Development Agent with gap 0x01
     - Wait for "Implemented – Pending Test" status
  
  2. Invoke Testing Agent for gap 0x01
     - Wait for "Tested – Pending QA" status
  
  3. Continue through QA → UAT → Platform QA → Security gates
  
  4. Once 0x01 is closed, wave_2 and wave_3 can run in parallel
EOF
    
    log_success "Dispatch plan generated: ${dispatch_dir}/dispatch-plan.yaml"
    
    # In a real implementation, we would invoke agents here
    log_warning "Manual agent invocation required - dispatch plan saved for reference"
}

# ============================================================================
# PHASE 4: VERIFICATION
# ============================================================================

verify_gates() {
    local iteration=$1
    log_section "ITERATION ${iteration}: GATE VERIFICATION"
    
    local verify_dir="${ITERATION_DIR}/iteration-${iteration}/verification"
    mkdir -p "${verify_dir}"
    
    log_info "Running verification checks..."
    
    # Build verification
    log_info "Checking build status..."
    cd "${REPO_ROOT}/apps/macos-legacy"
    if swift build 2>&1 > "${verify_dir}/build.log"; then
        log_success "Build verification: PASS"
        echo "build: PASS" > "${verify_dir}/gates.yaml"
    else
        log_error "Build verification: FAIL"
        echo "build: FAIL" > "${verify_dir}/gates.yaml"
    fi
    cd "${REPO_ROOT}"
    
    # Test verification
    log_info "Checking test status..."
    cd "${REPO_ROOT}/apps/macos-legacy"
    if swift test 2>&1 > "${verify_dir}/test.log"; then
        log_success "Test verification: PASS"
        echo "tests: PASS" >> "${verify_dir}/gates.yaml"
    else
        log_warning "Test verification: FAIL (or no tests)"
        echo "tests: FAIL" >> "${verify_dir}/gates.yaml"
    fi
    cd "${REPO_ROOT}"
    
    log_success "Gate verification complete"
}

# ============================================================================
# PHASE 5: CDIF/MCP UPDATE (Simulated)
# ============================================================================

update_cdif_mcp() {
    local iteration=$1
    log_section "ITERATION ${iteration}: CDIF/MCP UPDATE"
    
    local update_dir="${ITERATION_DIR}/iteration-${iteration}/cdif-mcp"
    mkdir -p "${update_dir}"
    
    cat > "${update_dir}/cdif-updates.yaml" << EOF
# CDIF Updates - Iteration ${iteration}
# Generated: $(date -Iseconds)

updates:
  - action: UPDATE_STATUS
    timestamp: "$(date -Iseconds)"
    iteration: ${iteration}
    notes: "Iteration ${iteration} complete"

# In a full implementation, each closed gap would generate:
# - CDIF child object update with implementation details
# - MCP task status transition
# - Evidence attachment (files, test results, build artifacts)
EOF
    
    log_success "CDIF/MCP updates recorded: ${update_dir}/cdif-updates.yaml"
}

# ============================================================================
# PHASE 6: CONVERGENCE CHECK
# ============================================================================

check_convergence() {
    local iteration=$1
    local analysis_dir="${ITERATION_DIR}/iteration-${iteration}/gap-analysis"
    
    log_section "ITERATION ${iteration}: CONVERGENCE CHECK"
    
    OPEN_GAPS=$(cat "${analysis_dir}/open-count.txt" 2>/dev/null || echo "999")
    
    if [ "${OPEN_GAPS}" -eq 0 ]; then
        log_success "🎉 CONVERGENCE ACHIEVED!"
        log_success "All ${SCOPE} gaps have been closed."
        return 0  # Converged
    else
        log_warning "Convergence NOT achieved"
        log_info "Open gaps remaining: ${OPEN_GAPS}"
        return 1  # Not converged
    fi
}

# ============================================================================
# MAIN ITERATION LOOP
# ============================================================================

main() {
    local iteration=1
    local converged=false
    
    log_header "STARTING ITERATIVE GAP CLOSURE"
    
    while [ "${iteration}" -le "${MAX_ITERATIONS}" ] && [ "${converged}" = "false" ]; do
        
        log_header "ITERATION ${iteration} OF ${MAX_ITERATIONS}"
        
        # Phase 1: Gap Analysis
        run_gap_analysis "${iteration}"
        OPEN_GAPS=$?
        
        # Check for early convergence
        if [ "${OPEN_GAPS}" -eq 0 ]; then
            check_convergence "${iteration}"
            converged=true
            break
        fi
        
        # Phase 2: Generate Master Document
        generate_master_document "${iteration}"
        
        # Phase 3: Dispatch Swarm
        dispatch_swarm "${iteration}"
        
        # Phase 4: Verification
        verify_gates "${iteration}"
        
        # Phase 5: CDIF/MCP Update
        update_cdif_mcp "${iteration}"
        
        # Phase 6: Convergence Check
        if check_convergence "${iteration}"; then
            converged=true
            break
        fi
        
        iteration=$((iteration + 1))
        
        # Pause for manual intervention
        if [ "${iteration}" -le "${MAX_ITERATIONS}" ] && [ "${converged}" = "false" ]; then
            log_warning "Manual agent work required before next iteration"
            log_info "Dispatch plan at: ${ITERATION_DIR}/iteration-$((iteration-1))/dispatch/dispatch-plan.yaml"
            log_info "To continue after agent work, re-run this script"
            break
        fi
    done
    
    # Final Summary
    log_header "ITERATION SUMMARY"
    
    if [ "${converged}" = "true" ]; then
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                    CONVERGENCE ACHIEVED                      ║${NC}"
        echo -e "${GREEN}║                                                              ║${NC}"
        echo -e "${GREEN}║  All ${SCOPE} gaps have been closed!                         ║${NC}"
        echo -e "${GREEN}║  The macOS app is ready for the next phase.                  ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║                   ITERATION PAUSED                           ║${NC}"
        echo -e "${YELLOW}║                                                              ║${NC}"
        echo -e "${YELLOW}║  Manual agent work required to close remaining gaps.         ║${NC}"
        echo -e "${YELLOW}║  Review dispatch plan and invoke agents accordingly.         ║${NC}"
        echo -e "${YELLOW}║  Re-run this script after agent work to continue.            ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    fi
    
    echo ""
    echo "Output directory: ${ITERATION_DIR}"
    echo "Completed: $(date)"
}

# Run main
main "$@"
