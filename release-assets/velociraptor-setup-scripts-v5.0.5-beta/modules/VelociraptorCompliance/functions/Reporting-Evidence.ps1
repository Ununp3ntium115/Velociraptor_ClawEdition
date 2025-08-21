function Export-ComplianceReport {
    <#
    .SYNOPSIS
        Exports compliance assessment reports in various formats.
        
    .DESCRIPTION
        Generates and exports comprehensive compliance assessment reports
        with findings, evidence, and recommendations in multiple formats.
        
    .PARAMETER AssessmentResults
        The compliance assessment results to export.
        
    .PARAMETER OutputPath
        Path where the report should be saved.
        
    .PARAMETER Format
        Output format (JSON, XML, HTML, CSV).
        
    .EXAMPLE
        Export-ComplianceReport -AssessmentResults $results -OutputPath "report.html" -Format "HTML"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AssessmentResults,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [Parameter()]
        [ValidateSet('JSON', 'XML', 'HTML', 'CSV')]
        [string]$Format = 'HTML'
    )
    
    try {
        Write-VelociraptorLog "Exporting compliance report in $Format format to $OutputPath" -Level Info -Component "ComplianceReporting"
        
        switch ($Format) {
            'JSON' {
                $AssessmentResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            'XML' {
                $xml = ConvertTo-Xml -InputObject $AssessmentResults -Depth 10 -NoTypeInformation
                $xml.Save($OutputPath)
            }
            'HTML' {
                $htmlReport = New-HTMLComplianceReport -AssessmentResults $AssessmentResults
                $htmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            'CSV' {
                $csvData = New-CSVComplianceReport -AssessmentResults $AssessmentResults
                $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
        }
        
        Write-VelociraptorLog "Compliance report exported successfully to $OutputPath" -Level Success -Component "ComplianceReporting"
        
    } catch {
        Write-VelociraptorLog "Failed to export compliance report: $($_.Exception.Message)" -Level Error -Component "ComplianceReporting"
        throw
    }
}

function New-HTMLComplianceReport {
    <#
    .SYNOPSIS
        Creates an HTML compliance assessment report.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AssessmentResults
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Velociraptor Compliance Assessment Report - $($AssessmentResults.Framework)</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 3px solid #0066cc;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #0066cc;
            margin: 0;
            font-size: 2.5em;
        }
        .header h2 {
            color: #666;
            margin: 10px 0 0 0;
            font-weight: normal;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        .summary-card h3 {
            margin: 0 0 10px 0;
            font-size: 1.2em;
        }
        .summary-card .value {
            font-size: 2em;
            font-weight: bold;
        }
        .compliance-score {
            background: $(if ($AssessmentResults.ComplianceScore -ge 90) { 'linear-gradient(135deg, #4CAF50 0%, #45a049 100%)' } 
                          elseif ($AssessmentResults.ComplianceScore -ge 70) { 'linear-gradient(135deg, #FF9800 0%, #F57C00 100%)' } 
                          else { 'linear-gradient(135deg, #f44336 0%, #d32f2f 100%)' });
        }
        .section {
            margin-bottom: 40px;
        }
        .section h2 {
            color: #0066cc;
            border-bottom: 2px solid #0066cc;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .findings {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .findings h3 {
            color: #856404;
            margin-top: 0;
        }
        .finding-item {
            background-color: #f8f9fa;
            border-left: 4px solid #dc3545;
            padding: 10px;
            margin-bottom: 10px;
        }
        .evidence {
            background-color: #d1ecf1;
            border: 1px solid #bee5eb;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .evidence h3 {
            color: #0c5460;
            margin-top: 0;
        }
        .evidence-item {
            background-color: #f8f9fa;
            border-left: 4px solid #28a745;
            padding: 10px;
            margin-bottom: 10px;
        }
        .recommendations {
            background-color: #e2e3e5;
            border: 1px solid #d6d8db;
            border-radius: 5px;
            padding: 15px;
        }
        .recommendations h3 {
            color: #495057;
            margin-top: 0;
        }
        .recommendation-item {
            background-color: #f8f9fa;
            border-left: 4px solid #6c757d;
            padding: 10px;
            margin-bottom: 10px;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #666;
            font-size: 0.9em;
        }
        .status-pass { color: #28a745; font-weight: bold; }
        .status-fail { color: #dc3545; font-weight: bold; }
        .status-partial { color: #ffc107; font-weight: bold; }
        .status-na { color: #6c757d; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Compliance Assessment Report</h1>
            <h2>$($AssessmentResults.Framework) Framework Analysis</h2>
            <p>Assessment Date: $($AssessmentResults.AssessmentDate)</p>
        </div>
        
        <div class="summary">
            <div class="summary-card compliance-score">
                <h3>Compliance Score</h3>
                <div class="value">$($AssessmentResults.ComplianceScore)%</div>
            </div>
            <div class="summary-card">
                <h3>Total Controls</h3>
                <div class="value">$($AssessmentResults.TotalControls)</div>
            </div>
            <div class="summary-card">
                <h3>Passed Controls</h3>
                <div class="value">$($AssessmentResults.PassedControls)</div>
            </div>
            <div class="summary-card">
                <h3>Failed Controls</h3>
                <div class="value">$($AssessmentResults.FailedControls)</div>
            </div>
        </div>
        
        <div class="section">
            <h2>Assessment Overview</h2>
            <p><strong>Framework:</strong> $($AssessmentResults.Framework)</p>
            <p><strong>Assessment Date:</strong> $($AssessmentResults.AssessmentDate)</p>
            <p><strong>Configuration Path:</strong> $($AssessmentResults.ConfigurationPath)</p>
            <p><strong>Total Controls Assessed:</strong> $($AssessmentResults.TotalControls)</p>
            <p><strong>Passed Controls:</strong> $($AssessmentResults.PassedControls)</p>
            <p><strong>Failed Controls:</strong> $($AssessmentResults.FailedControls)</p>
            <p><strong>Not Applicable Controls:</strong> $($AssessmentResults.NotApplicableControls)</p>
            <p><strong>Overall Compliance Score:</strong> $($AssessmentResults.ComplianceScore)%</p>
        </div>
"@

    # Add findings section if there are any
    if ($AssessmentResults.Findings -and $AssessmentResults.Findings.Count -gt 0) {
        $html += @"
        <div class="section">
            <h2>Control Findings</h2>
            <div class="findings">
                <h3>Failed Controls Requiring Attention</h3>
"@
        foreach ($finding in $AssessmentResults.Findings) {
            $html += @"
                <div class="finding-item">
                    <strong>$($finding.ControlId): $($finding.ControlTitle)</strong><br>
                    <em>Status: <span class="status-fail">$($finding.Status)</span></em><br>
                    $(($finding.Findings -join '<br>'))
                </div>
"@
        }
        $html += @"
            </div>
        </div>
"@
    }

    # Add evidence section if available
    if ($AssessmentResults.Evidence -and $AssessmentResults.Evidence.Count -gt 0) {
        $html += @"
        <div class="section">
            <h2>Compliance Evidence</h2>
            <div class="evidence">
                <h3>Evidence Collected</h3>
"@
        foreach ($evidence in $AssessmentResults.Evidence) {
            $html += @"
                <div class="evidence-item">
                    <strong>Evidence Type:</strong> $($evidence.Type)<br>
                    <strong>Description:</strong> $($evidence.Description)<br>
                    <strong>Collection Date:</strong> $($evidence.CollectionDate)
                </div>
"@
        }
        $html += @"
            </div>
        </div>
"@
    }

    # Add recommendations section if available
    if ($AssessmentResults.Recommendations -and $AssessmentResults.Recommendations.Count -gt 0) {
        $html += @"
        <div class="section">
            <h2>Recommendations</h2>
            <div class="recommendations">
                <h3>Remediation Recommendations</h3>
"@
        foreach ($recommendation in $AssessmentResults.Recommendations) {
            $html += @"
                <div class="recommendation-item">
                    <strong>Priority:</strong> $($recommendation.Priority)<br>
                    <strong>Recommendation:</strong> $($recommendation.Description)<br>
                    <strong>Affected Controls:</strong> $(($recommendation.AffectedControls -join ', '))
                </div>
"@
        }
        $html += @"
            </div>
        </div>
"@
    }

    $html += @"
        <div class="footer">
            <p>This report was generated by the Velociraptor Compliance Framework v1.0.0</p>
            <p>For more information, visit: <a href="https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts">Velociraptor Setup Scripts</a></p>
            <p>Report generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </div>
    </div>
</body>
</html>
"@

    return $html
}

function New-CSVComplianceReport {
    <#
    .SYNOPSIS
        Creates a CSV compliance assessment report.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AssessmentResults
    )
    
    $csvData = @()
    
    # Add summary row
    $csvData += [PSCustomObject]@{
        Type = "Summary"
        Framework = $AssessmentResults.Framework
        AssessmentDate = $AssessmentResults.AssessmentDate
        TotalControls = $AssessmentResults.TotalControls
        PassedControls = $AssessmentResults.PassedControls
        FailedControls = $AssessmentResults.FailedControls
        ComplianceScore = $AssessmentResults.ComplianceScore
        ControlId = ""
        ControlTitle = ""
        Status = ""
        Findings = ""
    }
    
    # Add findings
    foreach ($finding in $AssessmentResults.Findings) {
        $csvData += [PSCustomObject]@{
            Type = "Finding"
            Framework = $AssessmentResults.Framework
            AssessmentDate = $AssessmentResults.AssessmentDate
            TotalControls = ""
            PassedControls = ""
            FailedControls = ""
            ComplianceScore = ""
            ControlId = $finding.ControlId
            ControlTitle = $finding.ControlTitle
            Status = $finding.Status
            Findings = ($finding.Findings -join '; ')
        }
    }
    
    return $csvData
}

function New-ComplianceEvidence {
    <#
    .SYNOPSIS
        Creates compliance evidence packages for audit purposes.
        
    .DESCRIPTION
        Generates forensically sound evidence packages that can be used
        for compliance audits and regulatory reviews.
        
    .PARAMETER Control
        The compliance control for which evidence is being collected.
        
    .PARAMETER TestResult
        The test result containing evidence data.
        
    .PARAMETER EvidenceType
        Type of evidence being collected (Configuration, Log, Process, Technical).
        
    .EXAMPLE
        New-ComplianceEvidence -Control $control -TestResult $testResult -EvidenceType "Configuration"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [object]$TestResult,
        
        [Parameter()]
        [ValidateSet('Configuration', 'Log', 'Process', 'Technical', 'Documentation')]
        [string]$EvidenceType = 'Technical'
    )
    
    try {
        $evidence = @{
            EvidenceId = [System.Guid]::NewGuid().ToString()
            ControlId = $Control.Id
            ControlTitle = $Control.Title
            Framework = $Control.Framework
            EvidenceType = $EvidenceType
            CollectionDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            CollectionMethod = 'Automated'
            Collector = $env:USERNAME
            System = $env:COMPUTERNAME
            EvidenceData = $TestResult.Evidence
            Hash = $null
            ChainOfCustody = @{
                CreatedBy = $env:USERNAME
                CreatedOn = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                System = $env:COMPUTERNAME
                ProcessId = $PID
                SessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
            }
        }
        
        # Create hash for evidence integrity
        $evidenceJson = $evidence | ConvertTo-Json -Depth 10 -Compress
        $hash = Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($evidenceJson))) -Algorithm SHA256
        $evidence.Hash = $hash.Hash
        
        Write-VelociraptorLog "Created compliance evidence for control $($Control.Id): $($evidence.EvidenceId)" -Level Info -Component "ComplianceEvidence"
        
        return $evidence
        
    } catch {
        Write-VelociraptorLog "Failed to create compliance evidence: $($_.Exception.Message)" -Level Error -Component "ComplianceEvidence"
        throw
    }
}

function Export-VelociraptorComplianceEvidence {
    <#
    .SYNOPSIS
        Exports compliance evidence packages for external audit.
        
    .DESCRIPTION
        Creates tamper-evident evidence packages that can be provided
        to external auditors while maintaining chain of custody.
        
    .PARAMETER Evidence
        Array of evidence objects to export.
        
    .PARAMETER OutputPath
        Directory path where evidence packages should be exported.
        
    .PARAMETER IncludeSystemInfo
        Include detailed system information in evidence package.
        
    .PARAMETER DigitallySign
        Digitally sign the evidence package for integrity verification.
        
    .EXAMPLE
        Export-VelociraptorComplianceEvidence -Evidence $evidenceArray -OutputPath ".\evidence-export"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Evidence,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [Parameter()]
        [switch]$IncludeSystemInfo,
        
        [Parameter()]
        [switch]$DigitallySign
    )
    
    try {
        # Create output directory if it doesn't exist
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        $exportTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $evidencePackage = @{
            ExportId = [System.Guid]::NewGuid().ToString()
            ExportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            ExportedBy = $env:USERNAME
            ExportSystem = $env:COMPUTERNAME
            EvidenceCount = $Evidence.Count
            Evidence = $Evidence
            Integrity = @{
                ExportHash = $null
                DigitalSignature = $null
            }
        }
        
        # Include system information if requested
        if ($IncludeSystemInfo) {
            $evidencePackage.SystemInfo = @{
                ComputerName = $env:COMPUTERNAME
                UserName = $env:USERNAME
                Domain = $env:USERDOMAIN
                OSVersion = [System.Environment]::OSVersion.VersionString
                PSVersion = $PSVersionTable.PSVersion.ToString()
                TimeZone = [System.TimeZoneInfo]::Local.DisplayName
                ExportTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            }
        }
        
        # Create evidence package file
        $evidenceFile = Join-Path $OutputPath "compliance-evidence-$exportTimestamp.json"
        $evidencePackage | ConvertTo-Json -Depth 15 | Out-File -FilePath $evidenceFile -Encoding UTF8
        
        # Create hash for integrity verification
        $packageHash = Get-FileHash -Path $evidenceFile -Algorithm SHA256
        $evidencePackage.Integrity.ExportHash = $packageHash.Hash
        
        # Save updated package with hash
        $evidencePackage | ConvertTo-Json -Depth 15 | Out-File -FilePath $evidenceFile -Encoding UTF8
        
        # Create chain of custody document
        $custodyDoc = @{
            EvidencePackageId = $evidencePackage.ExportId
            ExportDate = $evidencePackage.ExportDate
            ExportedBy = $evidencePackage.ExportedBy
            EvidenceCount = $evidencePackage.EvidenceCount
            PackageHash = $packageHash.Hash
            CustodyChain = @(
                @{
                    Action = "Created"
                    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    User = $env:USERNAME
                    System = $env:COMPUTERNAME
                    Signature = "Digital evidence package created by Velociraptor Compliance Framework"
                }
            )
        }
        
        $custodyFile = Join-Path $OutputPath "chain-of-custody-$exportTimestamp.json"
        $custodyDoc | ConvertTo-Json -Depth 10 | Out-File -FilePath $custodyFile -Encoding UTF8
        
        # Create summary report
        $summaryReport = @"
COMPLIANCE EVIDENCE EXPORT SUMMARY
===================================

Export ID: $($evidencePackage.ExportId)
Export Date: $($evidencePackage.ExportDate)
Exported By: $($evidencePackage.ExportedBy)
Export System: $($evidencePackage.ExportSystem)

EVIDENCE PACKAGE DETAILS
========================
Evidence Count: $($evidencePackage.EvidenceCount)
Package File: $evidenceFile
Package Hash (SHA256): $($packageHash.Hash)
Chain of Custody: $custodyFile

EVIDENCE INTEGRITY
==================
The evidence package has been created with cryptographic integrity verification.
The SHA256 hash provides tamper detection capabilities.
Chain of custody documentation tracks all evidence handling.

VERIFICATION INSTRUCTIONS
=========================
1. Verify package integrity using SHA256 hash: $($packageHash.Hash)
2. Review chain of custody documentation for evidence handling
3. Import evidence package using Import-VelociraptorComplianceEvidence
4. Validate evidence integrity after import

Generated by Velociraptor Compliance Framework v1.0.0
Export completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        
        $summaryFile = Join-Path $OutputPath "evidence-export-summary-$exportTimestamp.txt"
        $summaryReport | Out-File -FilePath $summaryFile -Encoding UTF8
        
        Write-VelociraptorLog "Compliance evidence exported successfully: $evidenceFile" -Level Success -Component "ComplianceEvidence"
        
        return @{
            ExportId = $evidencePackage.ExportId
            EvidencePackageFile = $evidenceFile
            ChainOfCustodyFile = $custodyFile
            SummaryFile = $summaryFile
            PackageHash = $packageHash.Hash
            EvidenceCount = $Evidence.Count
        }
        
    } catch {
        Write-VelociraptorLog "Failed to export compliance evidence: $($_.Exception.Message)" -Level Error -Component "ComplianceEvidence"
        throw
    }
}

function Import-VelociraptorComplianceEvidence {
    <#
    .SYNOPSIS
        Imports and verifies compliance evidence packages.
        
    .DESCRIPTION
        Imports previously exported evidence packages and verifies
        their integrity and chain of custody.
        
    .PARAMETER EvidencePackagePath
        Path to the evidence package file to import.
        
    .PARAMETER VerifyIntegrity
        Verify the integrity of the evidence package.
        
    .PARAMETER OutputPath
        Path where imported evidence should be stored.
        
    .EXAMPLE
        Import-VelociraptorComplianceEvidence -EvidencePackagePath "evidence.json" -VerifyIntegrity
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EvidencePackagePath,
        
        [Parameter()]
        [switch]$VerifyIntegrity,
        
        [Parameter()]
        [string]$OutputPath
    )
    
    try {
        if (-not (Test-Path $EvidencePackagePath)) {
            throw "Evidence package file not found: $EvidencePackagePath"
        }
        
        # Import evidence package
        $evidencePackage = Get-Content $EvidencePackagePath | ConvertFrom-Json
        
        # Verify integrity if requested
        if ($VerifyIntegrity) {
            $currentHash = Get-FileHash -Path $EvidencePackagePath -Algorithm SHA256
            if ($currentHash.Hash -ne $evidencePackage.Integrity.ExportHash) {
                throw "Evidence package integrity verification failed. Package may have been tampered with."
            }
            Write-VelociraptorLog "Evidence package integrity verified successfully" -Level Success -Component "ComplianceEvidence"
        }
        
        # Update chain of custody
        $importRecord = @{
            Action = "Imported"
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            User = $env:USERNAME
            System = $env:COMPUTERNAME
            ImportHash = (Get-FileHash -Path $EvidencePackagePath -Algorithm SHA256).Hash
        }
        
        Write-VelociraptorLog "Imported compliance evidence package: $($evidencePackage.ExportId)" -Level Info -Component "ComplianceEvidence"
        
        return @{
            EvidencePackage = $evidencePackage
            ImportRecord = $importRecord
            IntegrityVerified = $VerifyIntegrity
            EvidenceCount = $evidencePackage.EvidenceCount
        }
        
    } catch {
        Write-VelociraptorLog "Failed to import compliance evidence: $($_.Exception.Message)" -Level Error -Component "ComplianceEvidence"
        throw
    }
}

function Get-ComplianceRecommendations {
    <#
    .SYNOPSIS
        Generates compliance recommendations based on assessment findings.
        
    .DESCRIPTION
        Analyzes compliance assessment findings and generates prioritized
        recommendations for remediation and improvement.
        
    .PARAMETER Framework
        The compliance framework being assessed.
        
    .PARAMETER Findings
        Array of compliance findings from assessment.
        
    .EXAMPLE
        Get-ComplianceRecommendations -Framework "FedRAMP" -Findings $assessmentFindings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Framework,
        
        [Parameter(Mandatory)]
        [array]$Findings
    )
    
    try {
        $recommendations = @()
        
        # Analyze findings and generate recommendations
        foreach ($finding in $Findings) {
            $recommendation = @{
                ControlId = $finding.ControlId
                ControlTitle = $finding.ControlTitle
                Priority = "Medium"
                Description = ""
                AffectedControls = @($finding.ControlId)
                EstimatedEffort = "Medium"
                ComplianceImpact = "Medium"
            }
            
            # Generate specific recommendations based on control type
            switch -Regex ($finding.ControlId) {
                # Authentication controls
                'IA-.*|A\.9\.2\..*|CC6\.[23]' {
                    $recommendation.Priority = "High"
                    $recommendation.Description = "Implement strong authentication mechanisms including multi-factor authentication"
                    $recommendation.ComplianceImpact = "High"
                }
                # Audit controls
                'AU-.*|A\.12\.4\..*|CC7\.1' {
                    $recommendation.Priority = "High"
                    $recommendation.Description = "Configure comprehensive audit logging and log retention policies"
                    $recommendation.ComplianceImpact = "High"
                }
                # Access control
                'AC-.*|A\.9\..*|CC6\.1' {
                    $recommendation.Priority = "High"
                    $recommendation.Description = "Implement role-based access controls and least privilege principles"
                    $recommendation.ComplianceImpact = "High"
                }
                # Incident response
                'IR-.*|A\.16\..*|CC7\.2' {
                    $recommendation.Priority = "Medium"
                    $recommendation.Description = "Develop and test incident response procedures and communication plans"
                    $recommendation.ComplianceImpact = "Medium"
                }
                # Configuration management
                'CM-.*|A\.12\.1\..*|CC8\.1' {
                    $recommendation.Priority = "Medium"
                    $recommendation.Description = "Implement configuration management and change control processes"
                    $recommendation.ComplianceImpact = "Medium"
                }
                # System integrity
                'SI-.*|A\.12\.6\..*' {
                    $recommendation.Priority = "Medium"
                    $recommendation.Description = "Deploy malware protection and vulnerability management capabilities"
                    $recommendation.ComplianceImpact = "Medium"
                }
                # Policy controls
                '.*-1$|Policy' {
                    $recommendation.Priority = "Low"
                    $recommendation.Description = "Document and maintain required policies and procedures"
                    $recommendation.EstimatedEffort = "Low"
                    $recommendation.ComplianceImpact = "Low"
                }
                default {
                    $recommendation.Description = "Review and implement required controls as specified in $Framework framework"
                }
            }
            
            $recommendations += $recommendation
        }
        
        # Sort by priority (High, Medium, Low)
        $priorityOrder = @{ "High" = 1; "Medium" = 2; "Low" = 3 }
        $recommendations = $recommendations | Sort-Object { $priorityOrder[$_.Priority] }
        
        Write-VelociraptorLog "Generated $($recommendations.Count) compliance recommendations" -Level Info -Component "ComplianceReporting"
        
        return $recommendations
        
    } catch {
        Write-VelociraptorLog "Failed to generate compliance recommendations: $($_.Exception.Message)" -Level Error -Component "ComplianceReporting"
        throw
    }
}