#!/bin/bash
# Create GitHub Issues for All 18 Gaps
# Usage: ./create-github-issues.sh

set -e

REPO="Ununp3ntium115/Velociraptor_ClawEdition"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Creating GitHub Issues for All 18 Gaps"
echo "Repository: $REPO"
echo ""

# Check if gh CLI is authenticated
if ! gh auth status &>/dev/null; then
    echo "❌ Error: GitHub CLI not authenticated"
    echo "Run: gh auth login"
    exit 1
fi

# Function to create an issue
create_issue() {
    local gap_id=$1
    local title=$2
    local priority=$3
    local body_file=$4
    
    echo "Creating issue for $gap_id: $title"
    
    gh issue create \
        --repo "$REPO" \
        --title "[$gap_id] $title" \
        --label "gap,$priority" \
        --body-file "$body_file" \
        --assignee "@me" \
        || {
            echo "⚠️  Failed to create issue for $gap_id"
            return 1
        }
    
    echo "✅ Created issue for $gap_id"
    echo ""
}

# Create all issues
echo "Creating P0 (Critical) issues..."
create_issue "gap-0x01" "Velociraptor API Client" "P0" "$SCRIPT_DIR/gap-0x01-velociraptor-api-client.md"
create_issue "gap-0x02" "Dashboard with Activity Timeline" "P0" "$SCRIPT_DIR/gap-0x02-dashboard-with-activity-timeline.md"
create_issue "gap-0x03" "Client Management Interface" "P0" "$SCRIPT_DIR/gap-0x03-client-management-interface.md"
create_issue "gap-0x04" "Hunt Management Interface" "P0" "$SCRIPT_DIR/gap-0x04-hunt-management-interface.md"
create_issue "gap-0x05" "VQL Terminal" "P0" "$SCRIPT_DIR/gap-0x05-vql-terminal.md"

echo "Creating P1 (High Priority) issues..."
create_issue "gap-0x06" "VFS Browser" "P1" "$SCRIPT_DIR/gap-0x06-vfs-browser.md"
create_issue "gap-0x07" "DFIR Tools Integration" "P1" "$SCRIPT_DIR/gap-0x07-dfir-tools-integration.md"
create_issue "gap-0x08" "WebSocket Real-Time Updates" "P1" "$SCRIPT_DIR/gap-0x08-websocket-real-time-updates.md"
create_issue "gap-0x09" "Accessibility Identifier Coverage" "P1" "$SCRIPT_DIR/gap-0x09-accessibility-identifier-coverage.md"

echo "Creating P2 (Medium Priority) issues..."
create_issue "gap-0x0A" "Notebooks Interface" "P2" "$SCRIPT_DIR/gap-0x0a-notebooks-interface.md"
create_issue "gap-0x0B" "Reports Generation" "P2" "$SCRIPT_DIR/gap-0x0b-reports-generation.md"
create_issue "gap-0x0C" "Evidence Management" "P2" "$SCRIPT_DIR/gap-0x0c-evidence-management.md"
create_issue "gap-0x0D" "SIEM/SOAR Integrations" "P2" "$SCRIPT_DIR/gap-0x0d-siem-soar-integrations.md"
create_issue "gap-0x0E" "Label Management" "P2" "$SCRIPT_DIR/gap-0x0e-label-management.md"
create_issue "gap-0x0F" "Package Management" "P2" "$SCRIPT_DIR/gap-0x0f-package-management.md"
create_issue "gap-0x10" "Training Interface" "P2" "$SCRIPT_DIR/gap-0x10-training-interface.md"
create_issue "gap-0x11" "Orchestration Panel" "P2" "$SCRIPT_DIR/gap-0x11-orchestration-panel.md"
create_issue "gap-0x12" "Logs Viewer Enhancement" "P2" "$SCRIPT_DIR/gap-0x12-logs-viewer-enhancement.md"

echo "✅ All issues created!"
echo ""
echo "Next steps:"
echo "1. Review issues: gh issue list --repo $REPO --label gap"
echo "2. Link issues to Master Iteration Document"
echo "3. Begin implementation with Phase 1 (gap-0x01, gap-0x08, gap-0x02)"
