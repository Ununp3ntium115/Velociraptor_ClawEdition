# Testing Agent CI/CD Integration Guide

## Overview

This guide explains how to integrate the macOS Testing Agent into your CI/CD pipeline for automated gap validation and continuous verification.

## GitHub Actions Integration

### Basic Workflow

Create `.github/workflows/macos-testing-agent.yml`:

```yaml
name: macOS Testing Agent

on:
  push:
    branches: [main, 'cursor/mac-os-*']
  pull_request:
    branches: [main]

jobs:
  validate-gaps:
    name: Validate Gap Closure
    runs-on: macos-14
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.2.app
    
    - name: Cache Swift dependencies
      uses: actions/cache@v3
      with:
        path: .build
        key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
        restore-keys: |
          ${{ runner.os }}-spm-
    
    - name: Build Testing Agent
      working-directory: VelociraptorMacOS
      run: swift build --target TestingAgentCLI
    
    - name: Run Testing Agent - Validate All Gaps
      working-directory: VelociraptorMacOS
      run: |
        swift run TestingAgentCLI --validate-all --format json > test-results.json
    
    - name: Upload Test Results
      uses: actions/upload-artifact@v4
      with:
        name: testing-agent-results
        path: VelociraptorMacOS/test-results.json
    
    - name: Generate Markdown Report
      if: always()
      working-directory: VelociraptorMacOS
      run: |
        swift run TestingAgentCLI --validate-all --format markdown > test-report.md
    
    - name: Comment PR with Results
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const report = fs.readFileSync('VelociraptorMacOS/test-report.md', 'utf8');
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: report
          });
```

### Advanced Workflow with Multiple Jobs

```yaml
name: macOS Testing Agent - Comprehensive

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  # Job 1: Unit Tests
  unit-tests:
    name: Run Unit Tests
    runs-on: macos-14
    steps:
    - uses: actions/checkout@v4
    - name: Run Swift Tests
      working-directory: VelociraptorMacOS
      run: swift test --enable-code-coverage
    
    - name: Generate Coverage Report
      run: |
        xcrun llvm-cov export \
          .build/debug/VelociraptorMacOSPackageTests.xctest/Contents/MacOS/VelociraptorMacOSPackageTests \
          -instr-profile .build/debug/codecov/default.profdata \
          -format lcov > coverage.lcov
    
    - name: Upload Coverage
      uses: codecov/codecov-action@v3
      with:
        files: coverage.lcov
  
  # Job 2: UI Tests
  ui-tests:
    name: Run UI Tests
    runs-on: macos-14
    steps:
    - uses: actions/checkout@v4
    - name: Install XcodeGen
      run: brew install xcodegen
    
    - name: Generate Xcode Project
      working-directory: VelociraptorMacOS
      run: xcodegen generate
    
    - name: Run UI Tests
      working-directory: VelociraptorMacOS
      run: |
        xcodebuild test \
          -project VelociraptorMacOS.xcodeproj \
          -scheme VelociraptorMacOS \
          -destination 'platform=macOS' \
          -only-testing:VelociraptorMacOSUITests \
          -resultBundlePath TestResults/UITests.xcresult
    
    - name: Upload UI Test Results
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: ui-test-results
        path: VelociraptorMacOS/TestResults/
  
  # Job 3: Gap Validation
  gap-validation:
    name: Validate Gaps
    runs-on: macos-14
    needs: [unit-tests, ui-tests]
    strategy:
      matrix:
        gap: [GAP-001, GAP-002, GAP-003, GAP-004, GAP-005]
    steps:
    - uses: actions/checkout@v4
    
    - name: Validate Gap ${{ matrix.gap }}
      working-directory: VelociraptorMacOS
      run: |
        swift run TestingAgentCLI \
          --gap ${{ matrix.gap }} \
          --format json \
          --runs 5 > gap-${{ matrix.gap }}-result.json
    
    - name: Upload Gap Result
      uses: actions/upload-artifact@v4
      with:
        name: gap-${{ matrix.gap }}-result
        path: VelociraptorMacOS/gap-${{ matrix.gap }}-result.json
  
  # Job 4: Generate CDIF Report
  cdif-report:
    name: Generate CDIF Report
    runs-on: macos-14
    needs: gap-validation
    steps:
    - uses: actions/checkout@v4
    
    - name: Generate CDIF Report
      working-directory: VelociraptorMacOS
      run: |
        swift run TestingAgentCLI \
          --validate-all \
          --format cdif > cdif-report.yaml
    
    - name: Upload CDIF Report
      uses: actions/upload-artifact@v4
      with:
        name: cdif-report
        path: VelociraptorMacOS/cdif-report.yaml
    
    - name: Archive CDIF Report
      run: |
        mkdir -p reports
        cp VelociraptorMacOS/cdif-report.yaml reports/cdif-$(date +%Y%m%d-%H%M%S).yaml
    
    - name: Commit CDIF Report
      if: github.ref == 'refs/heads/main'
      run: |
        git config user.name "Testing Agent Bot"
        git config user.email "bot@example.com"
        git add reports/
        git commit -m "Add CDIF report for $(date +%Y-%m-%d)"
        git push
```

## GitLab CI Integration

Create `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - test
  - validate
  - report

variables:
  XCODE_VERSION: "15.2"

build-testing-agent:
  stage: build
  tags:
    - macos
  script:
    - cd VelociraptorMacOS
    - swift build --target TestingAgentCLI
  artifacts:
    paths:
      - VelociraptorMacOS/.build/
    expire_in: 1 hour

unit-tests:
  stage: test
  tags:
    - macos
  script:
    - cd VelociraptorMacOS
    - swift test --enable-code-coverage
  artifacts:
    reports:
      junit: VelociraptorMacOS/test-results.xml

validate-gaps:
  stage: validate
  tags:
    - macos
  needs:
    - build-testing-agent
    - unit-tests
  script:
    - cd VelociraptorMacOS
    - swift run TestingAgentCLI --validate-all --format json | tee test-results.json
  artifacts:
    paths:
      - VelociraptorMacOS/test-results.json
    reports:
      junit: VelociraptorMacOS/test-results.xml

generate-cdif-report:
  stage: report
  tags:
    - macos
  needs:
    - validate-gaps
  script:
    - cd VelociraptorMacOS
    - swift run TestingAgentCLI --validate-all --format cdif > cdif-report.yaml
  artifacts:
    paths:
      - VelociraptorMacOS/cdif-report.yaml
    expire_in: 30 days
```

## Jenkins Pipeline

Create `Jenkinsfile`:

```groovy
pipeline {
    agent {
        label 'macos'
    }
    
    environment {
        XCODE_PATH = '/Applications/Xcode_15.2.app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Testing Agent') {
            steps {
                dir('VelociraptorMacOS') {
                    sh 'swift build --target TestingAgentCLI'
                }
            }
        }
        
        stage('Run Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        dir('VelociraptorMacOS') {
                            sh 'swift test --enable-code-coverage'
                        }
                    }
                }
                
                stage('UI Tests') {
                    steps {
                        dir('VelociraptorMacOS') {
                            sh '''
                                xcodegen generate
                                xcodebuild test \
                                    -project VelociraptorMacOS.xcodeproj \
                                    -scheme VelociraptorMacOS \
                                    -destination 'platform=macOS' \
                                    -only-testing:VelociraptorMacOSUITests
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Validate Gaps') {
            steps {
                dir('VelociraptorMacOS') {
                    sh '''
                        swift run TestingAgentCLI \
                            --validate-all \
                            --format json > test-results.json
                    '''
                }
            }
        }
        
        stage('Generate Reports') {
            steps {
                dir('VelociraptorMacOS') {
                    sh '''
                        swift run TestingAgentCLI \
                            --validate-all \
                            --format markdown > test-report.md
                        
                        swift run TestingAgentCLI \
                            --validate-all \
                            --format cdif > cdif-report.yaml
                    '''
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'VelociraptorMacOS/test-results.json, VelociraptorMacOS/test-report.md, VelociraptorMacOS/cdif-report.yaml', allowEmptyArchive: true
        }
        
        success {
            echo 'All gap validations passed!'
        }
        
        failure {
            echo 'Gap validation failed. Check reports for details.'
        }
    }
}
```

## Local Development Integration

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "Running Testing Agent pre-commit validation..."

cd VelociraptorMacOS

# Run critical gap validations
swift run TestingAgentCLI --gap GAP-003 --format console

if [ $? -ne 0 ]; then
    echo "❌ Gap validation failed. Commit aborted."
    exit 1
fi

echo "✅ Gap validation passed"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Pre-push Hook

Create `.git/hooks/pre-push`:

```bash
#!/bin/bash

echo "Running comprehensive gap validation before push..."

cd VelociraptorMacOS

# Run all gap validations
swift run TestingAgentCLI --validate-all --format console

if [ $? -ne 0 ]; then
    echo "❌ One or more gaps failed validation."
    echo "Push aborted. Fix issues before pushing."
    exit 1
fi

echo "✅ All gaps validated successfully"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-push
```

## Continuous Validation Schedule

### Daily Gap Validation (GitHub Actions)

```yaml
name: Daily Gap Validation

on:
  schedule:
    # Run at 2 AM UTC every day
    - cron: '0 2 * * *'
  workflow_dispatch: # Allow manual trigger

jobs:
  daily-validation:
    runs-on: macos-14
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Daily Validation
      working-directory: VelociraptorMacOS
      run: |
        swift run TestingAgentCLI --validate-all --format markdown > daily-report.md
    
    - name: Create Issue if Failed
      if: failure()
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const report = fs.readFileSync('VelociraptorMacOS/daily-report.md', 'utf8');
          
          github.rest.issues.create({
            owner: context.repo.owner,
            repo: context.repo.repo,
            title: `Daily Gap Validation Failed - ${new Date().toISOString().split('T')[0]}`,
            body: `# Daily Validation Report\n\n${report}`,
            labels: ['testing', 'gap-validation', 'automated']
          });
```

## Report Storage and Archival

### Store Reports in Artifacts

```yaml
- name: Archive Test Reports
  uses: actions/upload-artifact@v4
  with:
    name: test-reports-${{ github.run_number }}
    path: |
      VelociraptorMacOS/test-results.json
      VelociraptorMacOS/test-report.md
      VelociraptorMacOS/cdif-report.yaml
    retention-days: 90
```

### Store Reports in S3

```yaml
- name: Upload Reports to S3
  if: always()
  run: |
    aws s3 cp VelociraptorMacOS/test-results.json \
      s3://my-bucket/test-reports/$(date +%Y/%m/%d)/test-results-${{ github.run_number }}.json
    
    aws s3 cp VelociraptorMacOS/cdif-report.yaml \
      s3://my-bucket/test-reports/$(date +%Y/%m/%d)/cdif-report-${{ github.run_number }}.yaml
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_DEFAULT_REGION: us-east-1
```

## Notification Integration

### Slack Notifications

```yaml
- name: Send Slack Notification
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Gap Validation Failed",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Gap Validation Failed* :x:\n\nWorkflow: ${{ github.workflow }}\nRun: ${{ github.run_number }}"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Email Notifications

```yaml
- name: Send Email on Failure
  if: failure()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: Gap Validation Failed - ${{ github.repository }}
    body: |
      Gap validation failed in workflow ${{ github.workflow }}.
      
      Check the results at: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
    to: ${{ secrets.NOTIFICATION_EMAIL }}
    from: GitHub Actions
```

## Best Practices

### 1. Run on Every PR

Always validate gaps on pull requests to catch issues early:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
```

### 2. Cache Dependencies

Speed up builds by caching Swift dependencies:

```yaml
- uses: actions/cache@v3
  with:
    path: .build
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
```

### 3. Parallel Execution

Run gap validations in parallel for faster feedback:

```yaml
strategy:
  matrix:
    gap: [GAP-001, GAP-002, GAP-003, GAP-004, GAP-005]
```

### 4. Fail Fast

Use `fail-fast: false` to see all failures:

```yaml
strategy:
  fail-fast: false
  matrix:
    gap: [...]
```

### 5. Save All Reports

Always save reports even on failure:

```yaml
- uses: actions/upload-artifact@v4
  if: always()
```

## Troubleshooting

### Issue: Tests Fail in CI but Pass Locally

**Solution:** Check environment differences:
- Xcode version
- macOS version
- Environment variables
- File permissions

### Issue: Slow Test Execution

**Solution:** Use caching and parallel execution:
```yaml
- uses: actions/cache@v3
strategy:
  matrix:
    gap: [...]
```

### Issue: Flaky Tests in CI

**Solution:** Increase determinism run count:
```bash
swift run TestingAgentCLI --gap GAP-001 --runs 10
```

## References

- [Testing Agent README](VelociraptorMacOS/TestingAgent/README.md)
- [CDIF Test Archetypes](CDIF_TEST_ARCHETYPES.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI Documentation](https://docs.gitlab.com/ee/ci/)
