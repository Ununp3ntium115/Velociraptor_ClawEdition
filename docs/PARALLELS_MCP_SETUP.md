# Parallels MCP Server Setup Guide

This guide explains how to set up the Parallels MCP (Model Context Protocol) Server for developing the Velociraptor macOS application from a Windows host using Parallels Desktop.

## VS Code Sidebar Views

The Parallels Desktop extension provides these views in the VS Code sidebar:

| View ID | Name | Description |
|---------|------|-------------|
| `parallels-desktop-my-machines` | My Virtual Machines | List and manage all VMs |
| `parallels-desktop-remote-catalog` | My Catalogs | Browse VM templates/images |
| `parallels-desktop-remote-hosts` | My Remote Hosts | Manage remote Parallels hosts |
| `parallels-desktop-vagrant` | My Vagrant Boxes | Manage Vagrant environments |
| `parallels-desktop-help` | Helpful Links | Documentation and support |

**To access:** Click the Parallels icon in the VS Code Activity Bar (left sidebar).

## Overview

The Parallels MCP Server enables VS Code on Windows to:
- Control macOS VMs (start, stop, pause, resume)
- Execute Swift builds inside the macOS VM
- Run tests and manage the development workflow
- Integrate with AI assistants for VM-aware development

## Prerequisites

### On Windows Host

1. **Parallels Desktop Pro or Business** (version 18+)
2. **VS Code** with extensions:
   - `Parallels Desktop` extension
   - `Parallels MCP` extension
3. **Node.js** (for MCP server)

### On macOS VM

1. **macOS 13.0 (Ventura)** or later
2. **Xcode 16+** with command line tools
3. **Homebrew** for package management
4. **XcodeGen**: `brew install xcodegen`

## Installation

### Step 1: Install VS Code Extensions (Windows)

Open VS Code and install:

```
ext install parallels-desktop
ext install parallels-mcp
```

Or search for "Parallels Desktop" and "Parallels MCP" in the Extensions marketplace.

### Step 2: Configure Parallels Desktop

1. Open Parallels Desktop
2. Ensure your macOS VM is configured:
   - **Name**: `macOS-Development` (or update MCP config to match)
   - **Shared Folders**: Enable and share your project folder
   - **Network**: Use "Shared Network" mode

### Step 3: Start MCP Server

In VS Code Command Palette (`Ctrl+Shift+P`):

```
Parallels MCP: Start Server
```

Verify it's running:

```
Parallels MCP: Show Server Status
```

## VS Code Commands Reference

### MCP Server Commands

| Command | Description |
|---------|-------------|
| `Parallels MCP: Start Server` | Start the MCP server |
| `Parallels MCP: Stop Server` | Stop the MCP server |
| `Parallels MCP: Restart Server` | Restart the MCP server |
| `Parallels MCP: Show Server Status` | Display current server status |

### VM Management Commands

| Command | Description |
|---------|-------------|
| `Start VM` | Boot the macOS VM |
| `Stop VM` | Shutdown the macOS VM |
| `Pause VM` | Pause VM execution |
| `Resume VM` | Resume paused VM |
| `Suspend VM` | Suspend VM to disk |
| `Take VM Snapshot` | Create a snapshot |
| `Clone VM` | Clone the VM |

### Development Commands

| Command | Description |
|---------|-------------|
| `Get inside VM` | Open terminal in VM |
| `Copy Ip Address` | Copy VM's IP address |
| `View VM details` | Show VM configuration |

## Project Configuration

### MCP Settings (`.kiro/settings/mcp.json`)

```json
{
  "mcpServers": {
    "parallels-mcp": {
      "command": "parallels-mcp",
      "description": "Parallels Desktop MCP Server for VM management",
      "enabled": true,
      "settings": {
        "autoStart": true,
        "vmName": "macOS-Development",
        "hostAddress": "localhost",
        "port": 8080
      }
    }
  }
}
```

### VS Code Settings (`.vscode/settings.json`)

Add to your workspace settings:

```json
{
  "parallels-desktop.defaultVm": "macOS-Development",
  "parallels-mcp.autoStart": true,
  "parallels-mcp.logLevel": "info"
}
```

## Development Workflow

### Using the Sidebar Views

1. **Click Parallels icon** in the Activity Bar (left side)
2. **My Virtual Machines** view shows your VMs:
   - Right-click VM → Start/Stop/Pause
   - Right-click VM → Get inside VM (terminal)
   - Right-click VM → View VM details
3. **My Catalogs** view for downloading VM templates
4. **My Remote Hosts** for managing remote Parallels servers

### 1. Start Development Session

**Option A: Using Sidebar**
1. Open Parallels view in sidebar
2. Find `macOS-Development` in "My Virtual Machines"
3. Right-click → Start VM

**Option B: Using Command Palette**
```powershell
# From Windows Command Palette (Ctrl+Shift+P)
Parallels MCP: Start Server
# Then run task:
Tasks: Run Task → Parallels: Start macOS VM
```

### 2. Build in macOS VM

Open terminal in VM and run:

```bash
cd /Volumes/SharedFolder/Velociraptor_ClawEdition/VelociraptorMacOS

# Resolve Swift packages (first time)
swift package resolve

# Generate Xcode project
xcodegen generate

# Build
swift build -c release

# Run tests
swift test
```

### 3. Access from Windows

The project folder is shared, so you can:
- Edit Swift files in VS Code on Windows
- Build/test happens in macOS VM
- Use Parallels MCP to automate VM operations

## Shared Folder Setup

### Configure in Parallels

1. VM Settings → Options → Sharing
2. Enable "Share Windows folders with macOS"
3. Add your project folder
4. Choose mount point (e.g., `/Volumes/Projects`)

### Access in macOS VM

```bash
# Project will be available at:
/Volumes/Projects/Velociraptor_ClawEdition

# Or via Desktop shortcut:
~/Desktop/Projects/Velociraptor_ClawEdition
```

## Network Configuration

### Default IPs

| Machine | IP Address |
|---------|------------|
| Windows Host (from VM) | `10.211.55.2` |
| macOS VM (from Host) | `10.211.55.x` (dynamic) |

### Get VM IP

```powershell
# In VS Code
Right-click VM → Copy Ip Address
```

### SSH Access

```powershell
# From Windows PowerShell
ssh user@10.211.55.x
```

## Automation Scripts

### Build Script (`scripts/parallels-build.ps1`)

```powershell
# Run Swift build in macOS VM via Parallels
param(
    [string]$VMName = "macOS-Development",
    [string]$Configuration = "release"
)

# Ensure VM is running
prlctl start $VMName --wait

# Execute build command
prlctl exec $VMName -- bash -c "cd /Volumes/Projects/VelociraptorMacOS && swift build -c $Configuration"
```

### Test Script (`scripts/parallels-test.ps1`)

```powershell
# Run Swift tests in macOS VM
param(
    [string]$VMName = "macOS-Development"
)

prlctl exec $VMName -- bash -c "cd /Volumes/Projects/VelociraptorMacOS && swift test"
```

## Troubleshooting

### MCP Server Won't Start

1. Check Parallels Desktop is running
2. Verify VM exists with correct name
3. Restart VS Code
4. Check Output panel for errors

### VM Not Responding

```powershell
# Force stop and restart
prlctl stop macOS-Development --kill
prlctl start macOS-Development
```

### Shared Folders Not Visible

1. Install Parallels Tools in macOS VM
2. Restart VM after installation
3. Check Sharing settings in Parallels

### Swift Build Fails

```bash
# In macOS VM terminal
xcode-select --install
sudo xcodebuild -license accept
swift package resolve
```

### Network Connectivity Issues

1. Check VM network mode (should be "Shared")
2. Verify Windows Firewall allows Parallels
3. Try bridged networking if shared fails

## Best Practices

1. **Snapshots**: Take snapshots before major changes
2. **Resources**: Allocate 8GB+ RAM and 4+ CPU cores
3. **SSD**: Store VM on SSD for performance
4. **Updates**: Keep Parallels Tools updated
5. **Backups**: Regular VM backups

## Related Documentation

- [macOS Development Guide](MACOS_CONTRIBUTING.md)
- [Build and Release Process](../VelociraptorMacOS/README.md)
- [CI/CD Pipeline](../.github/workflows/macos-build.yml)

## Support

- Parallels Documentation: https://www.parallels.com/products/desktop/resources/
- VS Code Parallels Extension: Search "Parallels Desktop" in marketplace
- MCP Protocol: https://modelcontextprotocol.io/
