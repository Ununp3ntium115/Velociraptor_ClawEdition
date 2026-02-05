#Requires -Modules Pester

<#
.SYNOPSIS
    Script quality checks for deployment scripts.
#>

BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot '..\..\scripts\cross-platform\Deploy-VelociraptorMacOS.ps1'
    $scriptContent = Get-Content -Path $scriptPath -Raw
}

Describe "Script Quality" {
    It "Deploy-VelociraptorMacOS.ps1 should not contain empty catch blocks" {
        $scriptContent | Should -Not -Match 'catch\s*\{\s*\}'
    }
}
