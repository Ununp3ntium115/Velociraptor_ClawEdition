# 🦖 Git Workflow Commands for Beta Release

## Overview
This document provides the exact git commands needed to create the beta branch, push changes, and manage the release workflow.

---

## 🚀 Step 1: Prepare Feature Branch

### Create and Switch to Feature Branch
```bash
# Create new feature branch from main
git checkout main
git pull origin main
git checkout -b feature/enhanced-gui-encryption

# Verify you're on the correct branch
git branch --show-current
```

### Add All New and Modified Files
```bash
# Add all the new files we created
git add BETA_TESTING_PLAN.md
git add UAT_CHECKLIST.md
git add BETA_FEEDBACK_TEMPLATE.md
git add POST_BETA_ACTIONS.md
git add GITHUB_PR_TEMPLATE.md
git add GIT_WORKFLOW_COMMANDS.md
git add PULL_REQUEST_SUMMARY.md
git add test-enhanced-gui.ps1
git add demo-enhanced-gui.ps1

# Add modified GUI file
git add gui/VelociraptorGUI.ps1

# Check what's staged
git status
```

### Commit Changes with Descriptive Message
```bash
git commit -m "🦖 Add enhanced GUI with encryption options and beta testing framework

Features Added:
- Self-signed certificate support (default)
- Custom certificate file configuration  
- Let's Encrypt (AutoCert) integration
- Advanced security settings (environment, logging, TLS)
- Velociraptor dino branding throughout GUI
- Dynamic UI updates based on encryption selection
- Comprehensive YAML configuration generation

Testing Framework:
- Complete beta testing plan and UAT checklist
- Structured feedback collection template
- Post-beta actions workflow
- Validation and demo scripts

Ready for beta testing with comprehensive documentation."
```

### Push Feature Branch to Remote
```bash
# Push feature branch to GitHub
git push -u origin feature/enhanced-gui-encryption

# Verify push was successful
git log --oneline -5
```

---

## 🔄 Step 2: Create Pull Request

### Using GitHub CLI (if available)
```bash
# Create pull request using GitHub CLI
gh pr create \
  --title "🦖 Enhanced Velociraptor GUI with Encryption Options - Beta Ready" \
  --body-file GITHUB_PR_TEMPLATE.md \
  --base main \
  --head feature/enhanced-gui-encryption \
  --label "enhancement,beta-ready,security" \
  --reviewer @reviewer1,@reviewer2

# View created PR
gh pr view
```

### Using GitHub Web Interface
If GitHub CLI is not available:
1. Go to GitHub repository
2. Click "Compare & pull request" button
3. Copy content from `GITHUB_PR_TEMPLATE.md`
4. Paste into PR description
5. Add reviewers and labels
6. Create pull request

---

## 🧪 Step 3: Create Beta Branch (After PR Approval)

### Create Beta Branch from Feature Branch
```bash
# Switch to approved feature branch
git checkout feature/enhanced-gui-encryption
git pull origin feature/enhanced-gui-encryption

# Create beta branch
git checkout -b beta/v1.0.0

# Push beta branch to remote
git push -u origin beta/v1.0.0
```

### Tag Beta Release
```bash
# Create annotated tag for beta release
git tag -a v1.0.0-beta.1 -m "🦖 Velociraptor Setup Scripts v1.0.0 Beta 1

Enhanced GUI Features:
- Self-signed certificate support
- Custom certificate configuration
- Let's Encrypt integration
- Advanced security settings
- Velociraptor branding

Ready for comprehensive beta testing."

# Push tag to remote
git push origin v1.0.0-beta.1
```

---

## 📋 Step 4: Beta Testing Workflow

### Create Beta Testing Branch for Each Tester (Optional)
```bash
# Create individual testing branches if needed
git checkout beta/v1.0.0

# For Windows tester
git checkout -b beta/windows-testing
git push -u origin beta/windows-testing

# For Linux tester  
git checkout -b beta/linux-testing
git push -u origin beta/linux-testing

# For macOS tester
git checkout -b beta/macos-testing
git push -u origin beta/macos-testing
```

### Monitor Beta Testing Progress
```bash
# Check all beta-related branches
git branch -a | grep beta

# View beta testing commits
git log --oneline --graph beta/v1.0.0

# Check for any hotfixes during beta
git log --since="1 week ago" --grep="hotfix"
```

---

## 🔧 Step 5: Handle Beta Feedback and Fixes

### Create Hotfix Branch for Critical Issues
```bash
# Create hotfix branch from beta
git checkout beta/v1.0.0
git checkout -b hotfix/critical-issue-fix

# Make necessary fixes
# ... edit files ...

# Commit hotfix
git add .
git commit -m "🔧 Hotfix: Resolve critical issue found in beta testing

Issue: [Description of issue]
Fix: [Description of fix]
Tested: [Platforms tested]
Severity: Critical"

# Push hotfix branch
git push -u origin hotfix/critical-issue-fix
```

### Merge Hotfix Back to Beta
```bash
# Switch to beta branch
git checkout beta/v1.0.0

# Merge hotfix
git merge hotfix/critical-issue-fix

# Push updated beta
git push origin beta/v1.0.0

# Create new beta tag
git tag -a v1.0.0-beta.2 -m "🔧 Beta 2: Critical hotfixes applied"
git push origin v1.0.0-beta.2

# Clean up hotfix branch
git branch -d hotfix/critical-issue-fix
git push origin --delete hotfix/critical-issue-fix
```

---

## 🚀 Step 6: Production Release Preparation

### Create Release Candidate
```bash
# After successful beta testing, create release candidate
git checkout beta/v1.0.0
git pull origin beta/v1.0.0

# Create release candidate branch
git checkout -b release/v1.0.0

# Update version numbers and final documentation
# ... make final updates ...

git add .
git commit -m "🚀 Prepare v1.0.0 release candidate

Beta testing completed successfully:
- All critical issues resolved
- Cross-platform compatibility confirmed
- Documentation updated based on feedback
- Performance benchmarks met

Ready for production release."

# Push release candidate
git push -u origin release/v1.0.0
```

### Final Production Release
```bash
# Create final release tag
git tag -a v1.0.0 -m "🦖 Velociraptor Setup Scripts v1.0.0 - Production Release

Major Features:
- Enhanced GUI with encryption options
- Self-signed, custom, and Let's Encrypt certificate support
- Advanced security and environment settings
- Professional velociraptor branding
- Cross-platform compatibility
- Comprehensive documentation

Successfully completed beta testing with positive feedback.
Ready for production deployment."

# Push production tag
git push origin v1.0.0

# Merge to main branch
git checkout main
git pull origin main
git merge release/v1.0.0
git push origin main
```

---

## 🧹 Step 7: Cleanup and Maintenance

### Clean Up Branches After Release
```bash
# Delete feature branch (after successful release)
git branch -d feature/enhanced-gui-encryption
git push origin --delete feature/enhanced-gui-encryption

# Keep beta branch for reference but mark as archived
git checkout beta/v1.0.0
git tag -a beta/v1.0.0-archived -m "Archived beta branch after successful release"
git push origin beta/v1.0.0-archived

# Delete release candidate branch
git branch -d release/v1.0.0
git push origin --delete release/v1.0.0

# Clean up any testing branches
git push origin --delete beta/windows-testing
git push origin --delete beta/linux-testing
git push origin --delete beta/macos-testing
```

### Set Up for Next Development Cycle
```bash
# Create development branch for next version
git checkout main
git pull origin main
git checkout -b develop/v1.1.0

# Push development branch
git push -u origin develop/v1.1.0
```

---

## 📊 Step 8: Release Monitoring Commands

### Monitor Release Health
```bash
# Check recent commits on main
git log --oneline -10 main

# View all tags
git tag -l | sort -V

# Check branch status
git branch -a

# View release statistics
git shortlog --summary --numbered v1.0.0-beta.1..v1.0.0
```

### Emergency Rollback Commands
```bash
# If emergency rollback needed
git checkout main
git revert v1.0.0 --no-edit
git push origin main

# Create emergency patch
git checkout -b emergency/rollback-v1.0.0
git push -u origin emergency/rollback-v1.0.0
```

---

## 🎯 Quick Reference Commands

### Daily Beta Testing Commands
```bash
# Check beta status
git checkout beta/v1.0.0 && git pull origin beta/v1.0.0

# View recent beta activity
git log --oneline --since="1 day ago" beta/v1.0.0

# Check for new issues or feedback
git log --grep="fix\|bug\|issue" --since="1 day ago"
```

### Release Status Check
```bash
# View all releases
git tag -l | grep -E "v[0-9]+\.[0-9]+\.[0-9]+"

# Check current branch and status
git status && git branch --show-current

# View recent activity across all branches
git log --oneline --all --graph -10
```

---

## 🆘 Troubleshooting Commands

### Common Issues and Solutions

#### If Push is Rejected
```bash
# Pull latest changes first
git pull origin $(git branch --show-current)

# If conflicts, resolve and commit
git add .
git commit -m "Resolve merge conflicts"
git push origin $(git branch --show-current)
```

#### If Wrong Branch
```bash
# Check current branch
git branch --show-current

# Switch to correct branch
git checkout [correct-branch-name]

# If changes need to be moved
git stash
git checkout [correct-branch]
git stash pop
```

#### If Commit Message Wrong
```bash
# Amend last commit message (if not pushed yet)
git commit --amend -m "🦖 Corrected commit message"

# If already pushed, create new commit
git commit --allow-empty -m "📝 Clarification: [additional info]"
```

---

**🦖 These commands will help you navigate the entire beta testing and release workflow like a skilled velociraptor pack leader!**

*Remember to always verify your current branch and status before executing commands, and keep the team informed of major workflow steps.*