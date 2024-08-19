#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $SkipDependencies
)

#region Prerequisites

if (-not $SkipDependencies) {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'Invoke-Dependencies.ps1') `
        -Script $MyInvocation.MyCommand `
        -Confirm:$false
}

#endregion Prerequisites

#region Practice: Install Microsoft Graph Beta PowerShell module

$module = Get-Module -Name Microsoft.Graph.*
if ($module) {
    $module | Remove-Module -Force
}

# Install from Windows PowerShell to make module available in both editions

if ($psEditor -eq 'Desktop') {
    Write-Host 'Practice: Install Microsoft Graph Beta PowerShell module'
    
    . (Join-Path -Path $PSScriptRoot -ChildPath 'Install-MyModule.ps1')
    
    Install-MyModule `
        -Name 'Microsoft.Graph.Beta' `
        -Description 'Microsoft Graph Beta PowerShell module'
    
}

if ($PSEdition -ne 'Desktop') {
    $file = $MyInvocation.MyCommand.Path
    if ($MyInvocation.BoundParameters['Verbose'].IsPresent) {
        $verbose = '-Verbose'
    }
    powershell.exe -File $file -SkipDependencies $verbose
}

#endregion Practice: Install Microsoft Graph Beta PowerShell module