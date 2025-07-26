# Troubleshooting Guide

This guide helps you resolve common issues with the Velociraptor Setup Scripts. If you don't find your issue here, please check our [GitHub Issues](https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/issues) or create a new issue.

## 🚨 **Quick Diagnostics**

### **Health Check Command**
```powershell
# Run comprehensive health check
Test-VelociraptorHealth -ConfigPath "server.yaml" -IncludePerformance

# Quick status check
Get-VelociraptorStatus -ConfigPath "server.yaml"
```

### **Log File Locations**
- **Windows**: `C:\ProgramData\Velociraptor\logs\`
- **Linux**: `/var/log/velociraptor/`
- **macOS**: `~/Library/Logs/Velociraptor/`

---

## 🖥️ **GUI Issues**

### **GUI Won't Launch**

#### **Symptoms**
- BackColor null conversion errors
- "Cannot find Windows Forms" errors
- GUI crashes on startup

#### **Solutions**

**Windows Systems:**
```powershell
# Verify Windows Forms availability
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Launch GUI with error details
pwsh -File gui/VelociraptorGUI.ps1 -Verbose
```

**Non-Windows Systems:**
```bash
# Windows Forms not available on Linux/macOS
# Use command-line deployment instead
pwsh Deploy_Velociraptor_Standalone.ps1
```

#### **Common Fixes**
1. **Update PowerShell**: Ensure PowerShell 5.1+ or Core 7.0+
2. **Install .NET Framework**: Windows requires .NET Framework 4.7.2+
3. **Run as Administrator**: Some GUI operations require elevated privileges

### **GUI Display Issues**

#### **Symptoms**
- Controls not displaying correctly
- Text cut off or overlapping
- Dark theme not applied

#### **Solutions**
```powershell
# Reset GUI settings
Remove-Item "$env:APPDATA\VelociraptorGUI\settings.json" -ErrorAction SilentlyContinue

# Launch with safe mode
pwsh -File gui/VelociraptorGUI.ps1 -SafeMode
```

---

## 🌐 **Network Configuration Issues**

### **Port Already in Use**

#### **Symptoms**
- "Address already in use" errors
- Cannot bind to port 8000 or 8889
- Connection refused errors

#### **Solutions**

**Find Process Using Port:**
```powershell
# Windows
netstat -ano | findstr :8000
Get-Process -Id <PID>

# Linux/macOS
lsof -i :8000
ps -p <PID>
```

**Kill Conflicting Process:**
```powershell
# Windows
Stop-Process -Id <PID> -Force

# Linux/macOS
kill -9 <PID>
```

**Use Alternative Ports:**
```powershell
# Deploy with custom ports
Deploy-Velociraptor -BindPort 8001 -GUIPort 8890
```

### **Firewall Blocking Access**

#### **Symptoms**
- Cannot access GUI from browser
- Connection timeouts
- "This site can't be reached" errors

#### **Solutions**

**Windows Firewall:**
```powershell
# Add firewall rules
New-NetFirewallRule -DisplayName "Velociraptor API" -Direction Inbound -Port 8000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Velociraptor GUI" -Direction Inbound -Port 8889 -Protocol TCP -Action Allow
```

**Linux Firewall (UFW):**
```bash
sudo ufw allow 8000/tcp
sudo ufw allow 8889/tcp
sudo ufw reload
```

**macOS Firewall:**
```bash
# Add application to firewall exceptions
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/velociraptor
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /usr/local/bin/velociraptor
```

### **SSL Certificate Issues**

#### **Symptoms**
- "Certificate not trusted" warnings
- SSL handshake failures
- HTTPS connection errors

#### **Solutions**
```powershell
# Regenerate certificates
New-VelociraptorCertificate -ConfigPath "server.yaml" -Force

# Use HTTP for testing (not recommended for production)
Deploy-Velociraptor -UseHTTP
```

---

## 🔐 **Authentication Issues**

### **Cannot Login to GUI**

#### **Symptoms**
- "Invalid credentials" errors
- Login page redirects
- Session timeouts

#### **Solutions**

**Reset Admin Password:**
```powershell
# Reset to default credentials
Reset-VelociraptorCredentials -ConfigPath "server.yaml" -Username "admin" -Password "password"

# Generate secure password
$securePassword = New-VelociraptorPassword -Length 16
Set-VelociraptorCredentials -ConfigPath "server.yaml" -Username "admin" -Password $securePassword
```

**Check Configuration:**
```powershell
# Verify user configuration
Get-VelociraptorUsers -ConfigPath "server.yaml"

# Test authentication
Test-VelociraptorAuth -ConfigPath "server.yaml" -Username "admin" -Password "password"
```

### **Password Strength Issues**

#### **Symptoms**
- "Password too weak" warnings
- Password validation failures
- Security policy violations

#### **Solutions**
```powershell
# Generate strong password
$strongPassword = New-VelociraptorPassword -Length 16 -IncludeSymbols

# Validate password strength
Test-PasswordStrength -Password $strongPassword

# Update password policy
Set-VelociraptorPasswordPolicy -MinLength 12 -RequireSymbols $true
```

---

## 💾 **Storage and Database Issues**

### **Database Connection Failures**

#### **Symptoms**
- "Cannot connect to database" errors
- Database lock errors
- Corruption warnings

#### **Solutions**

**Check Database Status:**
```powershell
# Test database connectivity
Test-VelociraptorDatabase -ConfigPath "server.yaml"

# Repair database
Repair-VelociraptorDatabase -ConfigPath "server.yaml" -BackupFirst
```

**Database Permissions:**
```bash
# Linux - Fix permissions
sudo chown -R velociraptor:velociraptor /var/lib/velociraptor
sudo chmod -R 755 /var/lib/velociraptor

# Windows - Fix permissions
icacls "C:\ProgramData\Velociraptor" /grant "Everyone:(OI)(CI)F" /T
```

### **Disk Space Issues**

#### **Symptoms**
- "No space left on device" errors
- Slow performance
- Database growth warnings

#### **Solutions**
```powershell
# Check disk usage
Get-VelociraptorDiskUsage -ConfigPath "server.yaml"

# Clean old logs
Clear-VelociraptorLogs -ConfigPath "server.yaml" -OlderThan 30

# Archive old data
Export-VelociraptorData -ConfigPath "server.yaml" -ArchivePath "archive.zip" -OlderThan 90
```

---

## 🔧 **Deployment Issues**

### **Download Failures**

#### **Symptoms**
- "Failed to download binary" errors
- Network timeout errors
- Checksum validation failures

#### **Solutions**

**Manual Download:**
```powershell
# Download manually
$url = "https://github.com/Velocidx/velociraptor/releases/latest/download/velociraptor-windows-amd64.exe"
Invoke-WebRequest -Uri $url -OutFile "velociraptor.exe"

# Verify checksum
Get-FileHash "velociraptor.exe" -Algorithm SHA256
```

**Proxy Configuration:**
```powershell
# Configure proxy
$proxy = "http://proxy.company.com:8080"
Deploy-Velociraptor -ProxyUrl $proxy -ProxyCredential (Get-Credential)
```

**Offline Installation:**
```powershell
# Use offline installer
Deploy-Velociraptor -OfflineMode -BinaryPath "velociraptor.exe"
```

### **Permission Errors**

#### **Symptoms**
- "Access denied" errors
- "Insufficient privileges" warnings
- Service installation failures

#### **Solutions**

**Run as Administrator:**
```powershell
# Windows - Run as Administrator
Start-Process powershell -Verb RunAs -ArgumentList "-File Deploy_Velociraptor_Server.ps1"

# Linux - Use sudo
sudo pwsh Deploy_Velociraptor_Server.ps1

# Check current privileges
Test-AdminPrivileges
```

**Fix Service Permissions:**
```powershell
# Windows - Grant service permissions
Grant-ServicePermissions -ServiceName "Velociraptor" -Username "NT AUTHORITY\SYSTEM"

# Linux - Fix systemd permissions
sudo systemctl daemon-reload
sudo systemctl enable velociraptor
```

### **Configuration Validation Errors**

#### **Symptoms**
- YAML syntax errors
- Configuration validation failures
- Invalid parameter values

#### **Solutions**
```powershell
# Validate configuration
Test-VelociraptorConfig -ConfigPath "server.yaml" -Verbose

# Fix common issues
Repair-VelociraptorConfig -ConfigPath "server.yaml" -BackupOriginal

# Generate new configuration
New-VelociraptorConfig -DeploymentType Server -OutputPath "server-new.yaml"
```

---

## 🐳 **Container Issues**

### **Docker Deployment Problems**

#### **Symptoms**
- Container won't start
- Port binding failures
- Volume mount errors

#### **Solutions**

**Check Container Status:**
```bash
# View container logs
docker logs velociraptor-server

# Check container status
docker ps -a

# Restart container
docker restart velociraptor-server
```

**Fix Volume Permissions:**
```bash
# Fix volume permissions
sudo chown -R 1000:1000 ./velociraptor-data
docker run --rm -v $(pwd)/velociraptor-data:/data alpine chown -R 1000:1000 /data
```

**Port Conflicts:**
```bash
# Use different ports
docker run -p 8001:8000 -p 8890:8889 velociraptor:latest
```

### **Kubernetes Deployment Issues**

#### **Symptoms**
- Pod crashes
- Service not accessible
- Persistent volume issues

#### **Solutions**
```bash
# Check pod status
kubectl get pods -n velociraptor
kubectl describe pod velociraptor-server-xxx -n velociraptor

# Check logs
kubectl logs velociraptor-server-xxx -n velociraptor

# Fix persistent volume
kubectl delete pvc velociraptor-data -n velociraptor
kubectl apply -f kubernetes/velociraptor-pvc.yaml
```

---

## 🔍 **Performance Issues**

### **Slow Performance**

#### **Symptoms**
- Slow GUI response
- High CPU usage
- Memory consumption

#### **Solutions**
```powershell
# Monitor performance
Get-VelociraptorPerformance -ConfigPath "server.yaml" -Duration 300

# Optimize configuration
Optimize-VelociraptorConfig -ConfigPath "server.yaml"

# Tune database
Optimize-VelociraptorDatabase -ConfigPath "server.yaml"
```

### **Memory Issues**

#### **Symptoms**
- Out of memory errors
- Process crashes
- System slowdown

#### **Solutions**
```powershell
# Check memory usage
Get-Process velociraptor | Select-Object Name, WorkingSet, VirtualMemorySize

# Increase memory limits
Set-VelociraptorMemoryLimit -ConfigPath "server.yaml" -MaxMemoryMB 4096

# Enable memory optimization
Enable-VelociraptorMemoryOptimization -ConfigPath "server.yaml"
```

---

## 🔄 **Update and Upgrade Issues**

### **Update Failures**

#### **Symptoms**
- Update process hangs
- Version mismatch errors
- Configuration compatibility issues

#### **Solutions**
```powershell
# Manual update
Update-VelociraptorBinary -Force -BackupCurrent

# Fix configuration compatibility
Update-VelociraptorConfig -ConfigPath "server.yaml" -TargetVersion "0.6.7"

# Rollback if needed
Restore-VelociraptorBackup -BackupPath "backup-20250725.zip"
```

---

## 📊 **Monitoring and Logging**

### **Log Analysis**

#### **Common Log Patterns**
```bash
# Error patterns to look for
grep -i "error\|failed\|exception" /var/log/velociraptor/server.log

# Performance issues
grep -i "slow\|timeout\|memory" /var/log/velociraptor/server.log

# Authentication issues
grep -i "auth\|login\|credential" /var/log/velociraptor/server.log
```

#### **Enable Debug Logging**
```powershell
# Enable verbose logging
Set-VelociraptorLogLevel -ConfigPath "server.yaml" -Level Debug

# Monitor logs in real-time
Get-VelociraptorLogs -ConfigPath "server.yaml" -Follow
```

---

## 🆘 **Emergency Procedures**

### **Complete System Recovery**

#### **When Everything Fails**
```powershell
# 1. Stop all services
Stop-VelociraptorService -All

# 2. Backup current state
Backup-VelociraptorData -OutputPath "emergency-backup.zip"

# 3. Clean installation
Remove-Velociraptor -KeepData
Deploy-Velociraptor -FreshInstall

# 4. Restore data
Restore-VelociraptorData -BackupPath "emergency-backup.zip"
```

### **Factory Reset**
```powershell
# Complete reset (WARNING: Destroys all data)
Reset-VelociraptorInstallation -Confirm -RemoveData

# Clean reinstall
Deploy-Velociraptor -CleanInstall
```

---

## 📞 **Getting Additional Help**

### **Before Seeking Help**
1. **Check Logs**: Review relevant log files
2. **Run Diagnostics**: Use built-in diagnostic tools
3. **Search Issues**: Check existing GitHub issues
4. **Try Solutions**: Attempt relevant troubleshooting steps

### **When Creating Issues**
Include the following information:
- **Operating System**: Version and architecture
- **PowerShell Version**: `$PSVersionTable`
- **Velociraptor Version**: Binary and config versions
- **Error Messages**: Complete error messages and stack traces
- **Configuration**: Sanitized configuration file
- **Steps to Reproduce**: Detailed reproduction steps

### **Support Channels**
- **GitHub Issues**: https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/issues
- **GitHub Discussions**: https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/discussions
- **Documentation**: Check README.md and other documentation files

---

## 🔧 **Diagnostic Commands Reference**

### **System Information**
```powershell
# System diagnostics
Get-VelociraptorSystemInfo
Test-VelociraptorRequirements
Get-VelociraptorVersion -All

# Network diagnostics
Test-VelociraptorConnectivity
Get-VelociraptorNetworkConfig
Test-VelociraptorPorts

# Performance diagnostics
Get-VelociraptorPerformance
Test-VelociraptorHealth -Detailed
Measure-VelociraptorResponse
```

### **Configuration Diagnostics**
```powershell
# Configuration validation
Test-VelociraptorConfig -ConfigPath "server.yaml" -Verbose
Get-VelociraptorConfigSummary -ConfigPath "server.yaml"
Compare-VelociraptorConfig -Current "server.yaml" -Template "template.yaml"

# Security diagnostics
Test-VelociraptorSecurity -ConfigPath "server.yaml"
Get-VelociraptorSecurityStatus
Test-VelociraptorCertificates
```

---

**Remember**: When in doubt, check the logs first! Most issues can be diagnosed from the log files. If you're still stuck, don't hesitate to create a GitHub issue with detailed information about your problem.