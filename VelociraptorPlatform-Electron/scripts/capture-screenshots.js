/**
 * Electron App Screenshot Capture Script
 * 
 * Captures screenshots of all tabs/views in the Velociraptor Platform Electron app
 * for design reference when developing the macOS SwiftUI application.
 * 
 * Usage:
 *   npm run capture:screenshots
 *   node scripts/capture-screenshots.js
 * 
 * Output:
 *   screenshots/<timestamp>/<tab-name>.png
 */

const { _electron: electron } = require('playwright');
const path = require('path');
const fs = require('fs');

// Configuration
const SCREENSHOT_DIR = path.join(__dirname, '..', 'screenshots');
const DELAY_BETWEEN_TABS = 500; // ms to wait for tab to fully render
const WAIT_FOR_APP_READY = 2000; // ms to wait for app initialization

// All tabs to capture (from index.html navigation)
const TABS = [
    { id: 'wizard', name: '01-Setup-Wizard', description: 'Initial setup and configuration wizard' },
    { id: 'dashboard', name: '02-Dashboard', description: 'System overview, status cards, activity timeline' },
    { id: 'terminal', name: '03-Terminal', description: 'Integrated terminal for Velociraptor CLI' },
    { id: 'management', name: '04-Management', description: 'Client management, hunts, flows' },
    { id: 'labels', name: '05-Labels', description: 'Client labeling system' },
    { id: 'evidence', name: '06-Evidence', description: 'Evidence collection and chain of custody' },
    { id: 'hunt', name: '07-Hunt', description: 'Threat hunting interface' },
    { id: 'clients', name: '08-Clients', description: 'Endpoint management and monitoring' },
    { id: 'notebooks', name: '09-Notebooks', description: 'VQL notebooks' },
    { id: 'deploy', name: '10-Quick-Deploy', description: 'Quick deployment interface' },
    { id: 'tools', name: '11-Tools', description: 'DFIR tools management (25+ tools)' },
    { id: 'packages', name: '12-Packages', description: 'Package management' },
    { id: 'integrations', name: '13-Integrations', description: 'Third-party integrations' },
    { id: 'orchestration', name: '14-Orchestration', description: 'Automation and playbooks' },
    { id: 'training', name: '15-Training', description: '8 incident simulation scenarios' },
    { id: 'reports', name: '16-Reports', description: 'Report generation' },
    { id: 'logs', name: '17-Logs', description: 'Application logs' },
    { id: 'vfs', name: '18-VFS', description: 'Virtual File System browser' },
    { id: 'settings', name: '19-Settings', description: 'Application configuration' }
];

// Create timestamp-based directory
function createScreenshotDir() {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const dir = path.join(SCREENSHOT_DIR, timestamp);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    return dir;
}

// Main screenshot capture function
async function captureScreenshots() {
    console.log('='.repeat(60));
    console.log('Velociraptor Platform Electron Screenshot Capture');
    console.log('='.repeat(60));
    console.log(`\nCapturing ${TABS.length} tabs/views...\n`);

    const screenshotDir = createScreenshotDir();
    console.log(`Screenshot directory: ${screenshotDir}\n`);

    // Launch Electron app
    console.log('Launching Electron app...');
    const electronApp = await electron.launch({
        args: [path.join(__dirname, '..', 'electron.js')],
        env: {
            ...process.env,
            NODE_ENV: 'development'
        }
    });

    // Get the main window
    const window = await electronApp.firstWindow();
    console.log('Window opened successfully\n');

    // Wait for app to fully initialize
    await window.waitForTimeout(WAIT_FOR_APP_READY);
    
    // Wait for the sidebar to be ready
    console.log('Waiting for sidebar to load...');
    try {
        await window.waitForSelector('.sidebar .nav-list', { timeout: 10000 });
        console.log('Sidebar found');
    } catch (e) {
        console.log('Sidebar not found, waiting longer...');
        await window.waitForTimeout(3000);
    }
    
    // Debug: List all nav items found
    const navItems = await window.locator('.nav-item[data-tab]').all();
    console.log(`Found ${navItems.length} navigation items`);
    for (const item of navItems) {
        const tabId = await item.getAttribute('data-tab');
        console.log(`  - Tab: ${tabId}`);
    }

    // Maximize window for best screenshots
    await window.evaluate(() => {
        if (window.electronAPI && window.electronAPI.maximize) {
            window.electronAPI.maximize();
        }
    }).catch(() => {
        // Fallback - resize window
        console.log('Using fallback window resize');
    });

    // Set a good viewport size for screenshots
    await window.setViewportSize({ width: 1920, height: 1080 });

    const results = [];
    let successCount = 0;
    let failCount = 0;

    // Helper function to close any open modals
    async function closeModals() {
        try {
            // Try clicking outside modals or pressing Escape
            await window.keyboard.press('Escape');
            await window.waitForTimeout(100);
            
            // Try to click any close buttons on visible modals
            const closeButtons = window.locator('.modal .close-btn, .modal .btn-close, .modal [aria-label="Close"]');
            const count = await closeButtons.count();
            for (let i = 0; i < count; i++) {
                const btn = closeButtons.nth(i);
                if (await btn.isVisible()) {
                    await btn.click({ timeout: 1000 }).catch(() => {});
                }
            }
            
            // Also try clicking modal backdrop if it exists
            const backdrop = window.locator('.modal-backdrop, .modal-overlay');
            if (await backdrop.count() > 0 && await backdrop.first().isVisible()) {
                await backdrop.first().click({ force: true, timeout: 1000 }).catch(() => {});
            }
            
            await window.waitForTimeout(100);
        } catch (e) {
            // Ignore modal close errors
        }
    }

    // Capture each tab
    for (const tab of TABS) {
        console.log(`[${tab.name}] Navigating to tab...`);
        
        // Close any open modals first
        await closeModals();
        
        try {
            // Click on the navigation item
            const navItem = window.locator(`[data-tab="${tab.id}"]`);
            
            // Check if nav item exists
            const exists = await navItem.count() > 0;
            if (!exists) {
                console.log(`  ⚠️  Tab nav item not found: ${tab.id}`);
                results.push({ tab: tab.name, status: 'not_found', error: 'Nav item not found' });
                failCount++;
                continue;
            }

            // Click the tab
            await navItem.click();
            
            // Wait for tab content to render
            await window.waitForTimeout(DELAY_BETWEEN_TABS);
            
            // Additional wait for dynamic content
            const tabPane = window.locator(`#${tab.id}-tab`);
            if (await tabPane.count() > 0) {
                await tabPane.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {});
            }

            // Take screenshot
            const screenshotPath = path.join(screenshotDir, `${tab.name}.png`);
            await window.screenshot({ 
                path: screenshotPath,
                fullPage: false 
            });

            console.log(`  ✅ Screenshot saved: ${tab.name}.png`);
            results.push({ tab: tab.name, status: 'success', path: screenshotPath, description: tab.description });
            successCount++;

        } catch (error) {
            console.log(`  ❌ Error capturing ${tab.name}: ${error.message}`);
            results.push({ tab: tab.name, status: 'error', error: error.message });
            failCount++;
        }
    }

    // Capture additional screens if any dialogs/modals can be triggered
    console.log('\n[Additional Views] Attempting to capture modal/dialog states...');

    // Try to capture server admin tab if it exists
    try {
        const serverAdminNav = window.locator('[data-tab="server-admin"]');
        if (await serverAdminNav.count() > 0) {
            await serverAdminNav.click();
            await window.waitForTimeout(DELAY_BETWEEN_TABS);
            const screenshotPath = path.join(screenshotDir, '20-Server-Admin.png');
            await window.screenshot({ path: screenshotPath, fullPage: false });
            console.log('  ✅ Screenshot saved: 20-Server-Admin.png');
            results.push({ tab: '20-Server-Admin', status: 'success', path: screenshotPath, description: 'Server administration panel' });
            successCount++;
        }
    } catch (e) {
        console.log('  ⚠️  Server admin tab not accessible');
    }

    // Generate summary report
    const summaryPath = path.join(screenshotDir, 'CAPTURE_SUMMARY.json');
    const summary = {
        timestamp: new Date().toISOString(),
        totalTabs: TABS.length,
        successful: successCount,
        failed: failCount,
        screenshotDirectory: screenshotDir,
        results: results
    };
    fs.writeFileSync(summaryPath, JSON.stringify(summary, null, 2));

    // Generate markdown report
    const markdownPath = path.join(screenshotDir, 'DESIGN_REFERENCE.md');
    const markdown = generateMarkdownReport(results, summary);
    fs.writeFileSync(markdownPath, markdown);

    // Close the app
    await electronApp.close();

    // Print summary
    console.log('\n' + '='.repeat(60));
    console.log('CAPTURE COMPLETE');
    console.log('='.repeat(60));
    console.log(`✅ Successful: ${successCount}`);
    console.log(`❌ Failed: ${failCount}`);
    console.log(`\nScreenshots saved to: ${screenshotDir}`);
    console.log(`Summary report: ${summaryPath}`);
    console.log(`Design reference: ${markdownPath}`);
    console.log('='.repeat(60));

    return summary;
}

// Generate markdown design reference document
function generateMarkdownReport(results, summary) {
    let md = `# Velociraptor Platform Electron - Design Reference

Captured: ${summary.timestamp}

## Overview

This document provides a visual reference of the Velociraptor Platform Electron app's UI for porting to macOS SwiftUI.

- **Total Views**: ${summary.totalTabs}
- **Successfully Captured**: ${summary.successful}
- **Failed**: ${summary.failed}

## Screenshots

| Tab | Status | Description |
|-----|--------|-------------|
`;

    for (const result of results) {
        const statusIcon = result.status === 'success' ? '✅' : '❌';
        const desc = result.description || result.error || 'N/A';
        md += `| ${result.tab} | ${statusIcon} | ${desc} |\n`;
    }

    md += `
## Views Detail

`;

    for (const result of results.filter(r => r.status === 'success')) {
        md += `### ${result.tab}

${result.description || 'No description'}

![${result.tab}](./${result.tab}.png)

---

`;
    }

    md += `
## Notes for macOS SwiftUI Implementation

### Design Language
- The Electron app uses a dark theme with cyan/teal accent colors
- Icons are SVG-based, should be converted to SF Symbols where possible
- Layout uses a sidebar navigation pattern (similar to macOS apps)

### Key UI Components to Implement
1. **Sidebar Navigation** - Already implemented in macOS app
2. **Status Cards** - Dashboard widgets showing system status
3. **Terminal Emulator** - Integrated terminal view
4. **Data Tables** - Client lists, hunt results, artifacts
5. **Forms** - Configuration wizards, settings panels
6. **Modals/Dialogs** - Confirmation dialogs, detail views

### Color Palette (Approximate)
- Background: #1a1a2e, #16213e
- Accent: #00d9ff (cyan), #4fd1c5 (teal)
- Success: #48bb78
- Warning: #ed8936
- Error: #f56565
- Text: #e2e8f0 (primary), #a0aec0 (secondary)

### Typography
- Font: System font (segoe UI on Windows, SF Pro on macOS)
- Heading sizes: 24px (h1), 18px (h2), 16px (h3)
- Body: 14px

### Spacing
- Card padding: 16-24px
- Element spacing: 8-16px
- Sidebar width: ~200px
`;

    return md;
}

// Run the capture
captureScreenshots()
    .then(() => {
        console.log('\nScreenshot capture completed successfully!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\nFatal error:', error);
        process.exit(1);
    });
