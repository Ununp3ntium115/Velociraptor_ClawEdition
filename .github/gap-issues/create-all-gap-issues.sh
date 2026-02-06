#!/bin/bash
# Create GitHub Issues for All 18 Gaps
# This script creates GitHub issues for each gap identified in the macOS Implementation Guide

REPO="Ununp3ntium115/Velociraptor_ClawEdition"

# Function to create an issue
create_issue() {
    local gap_id=$1
    local title=$2
    local priority=$3
    local effort=$4
    local phase=$5
    local body_file=$6
    
    echo "Creating issue for $gap_id: $title"
    gh issue create \
        --repo "$REPO" \
        --title "[$gap_id] $title" \
        --label "gap,$priority" \
        --body-file "$body_file" \
        --assignee "@me"
}

# Create issues for all 18 gaps
# Note: This will create the issues. Make sure you're authenticated with gh auth login

echo "Creating GitHub issues for all 18 gaps..."
echo "Make sure you're authenticated: gh auth login"

# The actual issue creation will be done by reading the body files
# For now, we'll create the body files and then create issues

echo "Issue creation script ready. Run individual create_issue commands or use gh issue create with --body-file"
