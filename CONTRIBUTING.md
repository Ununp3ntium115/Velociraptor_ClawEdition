# Contributing to Velociraptor Setup Scripts

Thank you for your interest in contributing to the Velociraptor Setup Scripts project! This guide will help you get started with contributing to our enterprise-grade DFIR infrastructure automation platform.

## 🎯 **Project Overview**

The Velociraptor Setup Scripts project provides comprehensive automation for deploying, managing, and scaling Velociraptor DFIR infrastructure across traditional, cloud-native, and edge computing environments.

## 🚀 **Getting Started**

### **Prerequisites**
- **PowerShell**: 5.1+ or PowerShell Core 7.0+
- **Git**: For version control
- **Development Environment**: Windows, Linux, or macOS
- **Testing Tools**: Pester framework for PowerShell testing

### **Development Setup**
```bash
# Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/Velociraptor_Setup_Scripts.git
cd Velociraptor_Setup_Scripts

# Create a development branch
git checkout -b feature/your-feature-name

# Install development dependencies
Install-Module Pester -Force
Install-Module PSScriptAnalyzer -Force
```

## 📋 **Development Process**

### **1. Issue Creation**
- **Bug Reports**: Use the bug report template
- **Feature Requests**: Use the feature request template
- **Security Issues**: Report privately via security policy

### **2. Branch Strategy**
- **main**: Production-ready code
- **feature/**: New features and enhancements
- **bugfix/**: Bug fixes and patches
- **hotfix/**: Critical production fixes

### **3. Development Workflow**
1. **Create Issue**: Describe the problem or enhancement
2. **Fork Repository**: Create your own fork
3. **Create Branch**: Use descriptive branch names
4. **Develop**: Follow coding standards and best practices
5. **Test**: Add comprehensive tests
6. **Document**: Update documentation
7. **Submit PR**: Create pull request with detailed description

## 🛠️ **Coding Standards**

### **PowerShell Best Practices**
- **Approved Verbs**: Use only approved PowerShell verbs
- **Parameter Validation**: Implement comprehensive parameter validation
- **Error Handling**: Use try-catch blocks with meaningful error messages
- **Help Documentation**: Include comment-based help for all functions
- **Cross-Platform**: Ensure compatibility across Windows, Linux, macOS

### **Function Naming**
```powershell
# ✅ Good - Uses approved verb
function Get-VelociraptorStatus { }
function Set-VelociraptorConfiguration { }
function Test-VelociraptorHealth { }

# ❌ Bad - Uses unapproved verb
function Check-VelociraptorStatus { }
function Download-VelociraptorBinary { }
```

### **Parameter Validation**
```powershell
# ✅ Good - Comprehensive validation
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [ValidatePattern('\.ya?ml$')]
    [string]$ConfigPath,
    
    [ValidateSet('Server', 'Standalone', 'Client')]
    [string]$DeploymentType = 'Standalone'
)
```

### **Error Handling**
```powershell
# ✅ Good - Comprehensive error handling
try {
    $result = Invoke-SomeOperation -Path $ConfigPath
    Write-Verbose "Operation completed successfully"
    return $result
}
catch [System.IO.FileNotFoundException] {
    Write-Error "Configuration file not found: $ConfigPath"
    throw
}
catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
    throw
}
```

### **Documentation Standards**
```powershell
<#
.SYNOPSIS
    Brief description of the function

.DESCRIPTION
    Detailed description of what the function does

.PARAMETER ConfigPath
    Path to the Velociraptor configuration file

.EXAMPLE
    Get-VelociraptorStatus -ConfigPath "server.yaml"
    
    Gets the status of Velociraptor using the specified configuration

.NOTES
    Author: Your Name
    Version: 1.0.0
    
.LINK
    https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts
#>
```

## 🧪 **Testing Requirements**

### **Test Coverage**
- **Unit Tests**: Test individual functions
- **Integration Tests**: Test component interactions
- **Security Tests**: Validate security configurations
- **Cross-Platform Tests**: Ensure multi-platform compatibility

### **Pester Testing**
```powershell
# Example test structure
Describe "Get-VelociraptorStatus" {
    Context "When configuration file exists" {
        It "Should return status information" {
            # Arrange
            $configPath = "TestDrive:\test-config.yaml"
            "version: 1.0" | Out-File $configPath
            
            # Act
            $result = Get-VelociraptorStatus -ConfigPath $configPath
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "When configuration file is missing" {
        It "Should throw an error" {
            # Act & Assert
            { Get-VelociraptorStatus -ConfigPath "nonexistent.yaml" } | Should -Throw
        }
    }
}
```

### **Running Tests**
```powershell
# Run all tests
Invoke-Pester

# Run specific test file
Invoke-Pester -Path "tests/Deploy-Velociraptor.Tests.ps1"

# Run with coverage
Invoke-Pester -CodeCoverage "modules/**/*.ps1"
```

## 📚 **Documentation Guidelines**

### **Required Documentation**
- **Function Help**: Comment-based help for all functions
- **README Updates**: Update main README for new features
- **Examples**: Provide working examples
- **Troubleshooting**: Add common issues to troubleshooting guide

### **Documentation Standards**
- **Clear Language**: Use simple, clear language
- **Code Examples**: Include working code examples
- **Screenshots**: Add screenshots for GUI features
- **Links**: Link to relevant external documentation

## 🔒 **Security Guidelines**

### **Security Best Practices**
- **Input Validation**: Validate all user inputs
- **Credential Handling**: Never hardcode credentials
- **Secure Defaults**: Use secure default configurations
- **Audit Logging**: Log security-relevant events

### **Security Review Process**
- **Code Review**: All security-related changes require review
- **Vulnerability Scanning**: Run security scans on dependencies
- **Penetration Testing**: Test security configurations
- **Documentation**: Document security implications

## 🌐 **Cross-Platform Considerations**

### **Platform Compatibility**
- **Windows**: PowerShell 5.1+ and PowerShell Core 7.0+
- **Linux**: PowerShell Core 7.0+
- **macOS**: PowerShell Core 7.0+

### **Platform-Specific Code**
```powershell
# ✅ Good - Cross-platform path handling
$dataPath = if ($IsWindows) {
    "$env:ProgramData\Velociraptor"
} elseif ($IsLinux) {
    "/var/lib/velociraptor"
} elseif ($IsMacOS) {
    "$HOME/Library/Application Support/Velociraptor"
}
```

## 📝 **Pull Request Guidelines**

### **PR Requirements**
- **Descriptive Title**: Clear, concise title
- **Detailed Description**: Explain what and why
- **Issue Reference**: Link to related issues
- **Testing**: Include test results
- **Documentation**: Update relevant documentation

### **PR Template**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Cross-platform testing

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

### **Review Process**
1. **Automated Checks**: CI/CD pipeline validation
2. **Code Review**: Maintainer review
3. **Testing**: Comprehensive testing validation
4. **Security Review**: Security implications assessment
5. **Documentation Review**: Documentation completeness check

## 🏷️ **Release Process**

### **Version Numbering**
- **Major**: Breaking changes (x.0.0)
- **Minor**: New features (0.x.0)
- **Patch**: Bug fixes (0.0.x)
- **Pre-release**: Alpha/Beta releases (0.0.0-alpha.1)

### **Release Workflow**
1. **Feature Freeze**: Stop adding new features
2. **Testing**: Comprehensive testing phase
3. **Documentation**: Update all documentation
4. **Release Notes**: Create detailed changelog
5. **Tagging**: Create git tag and GitHub release

## 🤝 **Community Guidelines**

### **Code of Conduct**
- **Respectful**: Treat all contributors with respect
- **Inclusive**: Welcome contributors from all backgrounds
- **Constructive**: Provide constructive feedback
- **Professional**: Maintain professional communication

### **Communication Channels**
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Community Q&A and discussions
- **Pull Requests**: Code contributions and reviews

## 🎯 **Contribution Areas**

### **High Priority**
- **Bug Fixes**: Critical and high-priority bugs
- **Security Enhancements**: Security improvements
- **Cross-Platform Support**: Platform compatibility
- **Performance Optimization**: Performance improvements

### **Medium Priority**
- **New Features**: Additional functionality
- **Documentation**: Improved documentation
- **Testing**: Enhanced test coverage
- **User Experience**: UI/UX improvements

### **Low Priority**
- **Code Cleanup**: Refactoring and cleanup
- **Examples**: Additional examples and demos
- **Integrations**: Third-party integrations
- **Experimental Features**: Proof-of-concept features

## 📞 **Getting Help**

### **Resources**
- **Documentation**: Check existing documentation first
- **Issues**: Search existing issues for similar problems
- **Discussions**: Use GitHub Discussions for questions
- **Wiki**: Check project wiki for additional information

### **Contact**
- **Maintainers**: Tag maintainers in issues for urgent matters
- **Community**: Ask questions in GitHub Discussions
- **Security**: Use security policy for security issues

## 🙏 **Recognition**

Contributors are recognized in:
- **README**: Contributors section
- **Release Notes**: Acknowledgments in releases
- **GitHub**: Contributor statistics and graphs

Thank you for contributing to the Velociraptor Setup Scripts project! Your contributions help make DFIR infrastructure deployment easier and more reliable for security professionals worldwide.

---

**Happy Contributing! 🚀**