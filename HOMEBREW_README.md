# Velociraptor Setup Scripts - Homebrew Edition

Automated deployment scripts for [Velociraptor DFIR framework](https://github.com/Velocidex/velociraptor) optimized for macOS and Homebrew.

## Installation

### Via Homebrew (Recommended)

```bash
# Add the tap (once available)
brew tap ununp3ntium115/velociraptor-setup

# Install the package
brew install velociraptor-setup
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts.git
cd Velociraptor_Setup_Scripts

# Make scripts executable
chmod +x deploy-velociraptor-standalone.sh
chmod +x scripts/velociraptor-*.sh

# Run deployment
./deploy-velociraptor-standalone.sh
```

## Quick Start

After installation via Homebrew:

```bash
# Deploy Velociraptor standalone
velociraptor-deploy

# Check system health
velociraptor-health

# Cleanup installation
velociraptor-cleanup
```

## Features

### 🚀 Automated Deployment
- Downloads latest Velociraptor binary for macOS
- Configures proper macOS directory structure
- Sets up firewall rules automatically
- Creates launchd service for auto-start

### 🏥 Health Monitoring
- Comprehensive system health checks
- Process and network monitoring
- Resource usage validation
- Configuration verification

### 🧹 Clean Removal
- Safe uninstallation with data preservation options
- Complete cleanup or selective removal
- Automatic service stopping

### 🍎 macOS Optimized
- Follows Apple's directory conventions
- Uses `~/Library/Application Support/Velociraptor` for data
- Integrates with macOS firewall
- launchd service integration

## Directory Structure

```
~/Library/Application Support/Velociraptor/  # Main data directory
~/Library/Logs/Velociraptor/                 # Log files
~/Library/Caches/Velociraptor/               # Cache files
~/Library/LaunchAgents/                      # Auto-start configuration
/usr/local/bin/velociraptor                  # Binary location
```

## Commands

### Deploy Velociraptor
```bash
velociraptor-deploy
```

**Features:**
- Downloads latest macOS binary
- Sets up directory structure
- Configures firewall
- Starts GUI service
- Opens browser automatically

### Health Check
```bash
velociraptor-health [OPTIONS]

Options:
  --verbose    Show detailed output
  --json       Output results in JSON format
```

**Checks:**
- Binary installation
- Directory structure
- Process status
- Network connectivity
- Disk space
- System resources
- Log files
- Configuration

### Cleanup
```bash
velociraptor-cleanup [OPTIONS]

Options:
  --complete       Remove everything including data
  --preserve-data  Keep data and logs
```

**Actions:**
- Stops all services
- Removes binary
- Cleans cache
- Optional data removal

## Configuration

### Auto-start Service
```bash
# Enable auto-start
launchctl load ~/Library/LaunchAgents/com.velocidex.velociraptor.plist

# Disable auto-start
launchctl unload ~/Library/LaunchAgents/com.velocidex.velociraptor.plist
```

### Manual Service Control
```bash
# Start manually
/usr/local/bin/velociraptor gui --datastore "~/Library/Application Support/Velociraptor"

# Stop service
kill $(cat "~/Library/Application Support/Velociraptor/velociraptor.pid")
```

## Troubleshooting

### Common Issues

**Port 8889 already in use:**
```bash
# Find what's using the port
lsof -i :8889

# Kill the process if needed
kill -9 <PID>
```

**Permission denied:**
```bash
# Fix permissions
chmod +x /usr/local/bin/velociraptor
sudo chown $(whoami) "~/Library/Application Support/Velociraptor"
```

**Firewall blocking access:**
```bash
# Manually add firewall rule
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/velociraptor
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /usr/local/bin/velociraptor
```

### Log Files
- Main log: `~/Library/Logs/Velociraptor/velociraptor.log`
- Error log: `~/Library/Logs/Velociraptor/velociraptor.error.log`
- Deployment log: `~/Library/Logs/Velociraptor/standalone_deploy.log`

### Health Check
```bash
# Quick health check
velociraptor-health

# Detailed health check
velociraptor-health --verbose

# JSON output for automation
velociraptor-health --json
```

## Security Considerations

### Firewall Configuration
The deployment script automatically configures macOS firewall to allow Velociraptor. You can verify this with:

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps
```

### Data Protection
- All data stored in user's Library directory
- No system-wide modifications required
- Easy to backup and restore

### Network Security
- GUI accessible only on localhost by default
- HTTPS enabled with self-signed certificate
- Default credentials: admin/password (change immediately)

## Advanced Usage

### Custom Configuration
```bash
# Use custom configuration file
/usr/local/bin/velociraptor gui --config /path/to/custom.yaml
```

### Development Mode
```bash
# Run with verbose logging
/usr/local/bin/velociraptor gui --datastore "~/Library/Application Support/Velociraptor" -v
```

### Backup and Restore
```bash
# Backup data
tar -czf velociraptor-backup.tar.gz "~/Library/Application Support/Velociraptor"

# Restore data
tar -xzf velociraptor-backup.tar.gz -C ~/
```

## Requirements

- macOS 10.14 (Mojave) or later
- Homebrew package manager
- Internet connection for initial download
- Administrator privileges for firewall configuration

## Dependencies

The Homebrew formula automatically installs:
- `jq` - JSON processing
- `curl` - HTTP client

## Support

- **Issues**: [GitHub Issues](https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/issues)
- **Documentation**: [Velociraptor Docs](https://docs.velociraptor.app/)
- **Community**: [Velociraptor Discord](https://www.velocidex.com/discord)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on macOS
5. Submit a pull request

## Changelog

### v5.0.1
- Initial Homebrew support
- macOS-optimized deployment
- Health monitoring system
- Clean removal tools
- launchd integration