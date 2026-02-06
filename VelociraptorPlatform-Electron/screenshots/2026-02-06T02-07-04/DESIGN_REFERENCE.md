# Velociraptor Platform Electron - Design Reference

Captured: 2026-02-06T02:07:14.239Z

## Overview

This document provides a visual reference of the Velociraptor Platform Electron app's UI for porting to macOS SwiftUI.

- **Total Views**: 19
- **Successfully Captured**: 0
- **Failed**: 19

## Screenshots

| Tab | Status | Description |
|-----|--------|-------------|
| 01-Setup-Wizard | ❌ | Nav item not found |
| 02-Dashboard | ❌ | Nav item not found |
| 03-Terminal | ❌ | Nav item not found |
| 04-Management | ❌ | Nav item not found |
| 05-Labels | ❌ | Nav item not found |
| 06-Evidence | ❌ | Nav item not found |
| 07-Hunt | ❌ | Nav item not found |
| 08-Clients | ❌ | Nav item not found |
| 09-Notebooks | ❌ | Nav item not found |
| 10-Quick-Deploy | ❌ | Nav item not found |
| 11-Tools | ❌ | Nav item not found |
| 12-Packages | ❌ | Nav item not found |
| 13-Integrations | ❌ | Nav item not found |
| 14-Orchestration | ❌ | Nav item not found |
| 15-Training | ❌ | Nav item not found |
| 16-Reports | ❌ | Nav item not found |
| 17-Logs | ❌ | Nav item not found |
| 18-VFS | ❌ | Nav item not found |
| 19-Settings | ❌ | Nav item not found |

## Views Detail


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
