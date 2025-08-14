#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test all created incident response packages

.DESCRIPTION
    Validates all 7 specialized incident response packages for completeness,
    functionality, and deployment readiness.
#>

Write-Host "TESTING ALL INCIDENT RESPONSE PACKAGES" -ForegroundColor Green
Write-Host "=" * 55 -ForegroundColor Green

$packageTypes = @("Ransomware", "APT", "Insider", "Malware", "NetworkIntrusion", "DataBreach", "Complete")
$testResults = @{}

foreach ($packageType in $packageTypes) {
    Write-Host "`n📦 Testing $packageType Package..." -ForegroundColor Cyan
    
    $packagePath = ".\incident-packages\$packageType-Package"
    $zipPath = ".\incident-packages\$packageType-Package.zip"
    
    $testResult = @{
        PackageType = $packageType
        DirectoryExists = Test-Path $packagePath
        ZipExists = Test-Path $zipPath
        DeployScriptExists = $false
        ConfigExists = $false
        ManifestExists = $false
        ArtifactsCount = 0
        ToolsCount = 0
        Issues = @()
    }
    
    if ($testResult.DirectoryExists) {
        Write-Host "✅ Package directory exists" -ForegroundColor Green
        
        # Check for deployment script
        $deployScript = "$packagePath\Deploy-$packageType.ps1"
        if (Test-Path $deployScript) {
            $testResult.DeployScriptExists = $true
            Write-Host "✅ Deployment script exists" -ForegroundColor Green
        } else {
            $testResult.Issues += "Missing deployment script"
            Write-Host "❌ Deployment script missing" -ForegroundColor Red
        }
        
        # Check for configuration
        $configPath = "$packagePath\config"
        if (Test-Path $configPath) {
            $testResult.ConfigExists = $true
            Write-Host "✅ Configuration directory exists" -ForegroundColor Green
        } else {
            $testResult.Issues += "Missing configuration directory"
            Write-Host "❌ Configuration directory missing" -ForegroundColor Red
        }
        
        # Check for manifest
        $manifestPath = "$packagePath\package-manifest.json"
        if (Test-Path $manifestPath) {
            $testResult.ManifestExists = $true
            Write-Host "✅ Package manifest exists" -ForegroundColor Green
            
            try {
                $manifest = Get-Content $manifestPath | ConvertFrom-Json
                Write-Host "📊 Package Version: $($manifest.version)" -ForegroundColor Cyan
                Write-Host "📊 Package Type: $($manifest.package_type)" -ForegroundColor Cyan
                Write-Host "📊 Created: $($manifest.created)" -ForegroundColor Cyan
            } catch {
                $testResult.Issues += "Invalid manifest JSON"
                Write-Host "⚠️ Manifest JSON is invalid" -ForegroundColor Yellow
            }
        } else {
            $testResult.Issues += "Missing package manifest"
            Write-Host "❌ Package manifest missing" -ForegroundColor Red
        }
        
        # Count artifacts
        $artifactsPath = "$packagePath\artifacts"
        if (Test-Path $artifactsPath) {
            $artifacts = Get-ChildItem $artifactsPath -Filter "*.yaml" -ErrorAction SilentlyContinue
            $testResult.ArtifactsCount = $artifacts.Count
            Write-Host "📋 Artifacts: $($artifacts.Count)" -ForegroundColor Cyan
        }
        
        # Count tools
        $toolsPath = "$packagePath\tools"
        if (Test-Path $toolsPath) {
            $tools = Get-ChildItem $toolsPath -ErrorAction SilentlyContinue
            $testResult.ToolsCount = $tools.Count
            Write-Host "🔧 Tools: $($tools.Count)" -ForegroundColor Cyan
        }
        
    } else {
        $testResult.Issues += "Package directory does not exist"
        Write-Host "❌ Package directory missing" -ForegroundColor Red
    }
    
    if ($testResult.ZipExists) {
        $zipSize = (Get-Item $zipPath).Length / 1MB
        Write-Host "📦 ZIP size: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Cyan
    } else {
        $testResult.Issues += "ZIP package does not exist"
        Write-Host "❌ ZIP package missing" -ForegroundColor Red
    }
    
    $testResults[$packageType] = $testResult
}

# Generate summary report
Write-Host "`n🎯 PACKAGE TESTING SUMMARY" -ForegroundColor Green
Write-Host "=" * 40 -ForegroundColor Green

$totalPackages = $packageTypes.Count
$successfulPackages = 0

foreach ($packageType in $packageTypes) {
    $result = $testResults[$packageType]
    $issueCount = $result.Issues.Count
    
    if ($issueCount -eq 0) {
        $status = "✅ PASSED"
        $color = "Green"
        $successfulPackages++
    } elseif ($issueCount -le 2) {
        $status = "⚠️ PARTIAL"
        $color = "Yellow"
    } else {
        $status = "❌ FAILED"
        $color = "Red"
    }
    
    Write-Host "$packageType Package: $status" -ForegroundColor $color
    
    if ($issueCount -gt 0) {
        foreach ($issue in $result.Issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
}

$successRate = [math]::Round(($successfulPackages / $totalPackages) * 100, 1)
Write-Host "`n📊 Overall Success Rate: $successfulPackages/$totalPackages ($successRate%)" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })

# Test deployment readiness
Write-Host "`n🚀 DEPLOYMENT READINESS TEST" -ForegroundColor Green
Write-Host "=" * 35 -ForegroundColor Green

$readyForDeployment = @()
$needsWork = @()

foreach ($packageType in $packageTypes) {
    $result = $testResults[$packageType]
    
    if ($result.DirectoryExists -and $result.ZipExists -and $result.DeployScriptExists -and $result.ManifestExists) {
        $readyForDeployment += $packageType
        Write-Host "✅ $packageType - Ready for deployment" -ForegroundColor Green
    } else {
        $needsWork += $packageType
        Write-Host "⚠️ $packageType - Needs additional work" -ForegroundColor Yellow
    }
}

Write-Host "`n📋 DEPLOYMENT STATUS:" -ForegroundColor Cyan
Write-Host "Ready for deployment: $($readyForDeployment.Count)/$totalPackages" -ForegroundColor Green
Write-Host "Need additional work: $($needsWork.Count)/$totalPackages" -ForegroundColor Yellow

if ($readyForDeployment.Count -eq $totalPackages) {
    Write-Host "`n🎉 ALL PACKAGES READY FOR DEPLOYMENT!" -ForegroundColor Green
    Write-Host "🚀 You can now deploy any of the 7 specialized packages" -ForegroundColor Green
} elseif ($readyForDeployment.Count -ge ($totalPackages * 0.8)) {
    Write-Host "`n✅ MOST PACKAGES READY FOR DEPLOYMENT" -ForegroundColor Green
    Write-Host "🔧 Minor fixes needed for remaining packages" -ForegroundColor Yellow
} else {
    Write-Host "`n⚠️ ADDITIONAL WORK NEEDED" -ForegroundColor Yellow
    Write-Host "🛠️ Several packages need fixes before deployment" -ForegroundColor Yellow
}

# Generate detailed report
$reportPath = ".\Package-Testing-Report.json"
$testResults | ConvertTo-Json -Depth 3 | Out-File $reportPath
Write-Host "`n📄 Detailed report saved to: $reportPath" -ForegroundColor Cyan

Write-Host "`n🦖 Package testing completed!" -ForegroundColor Green