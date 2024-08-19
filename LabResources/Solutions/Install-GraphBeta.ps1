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

Write-Host 'Practice: Install Microsoft Graph Beta PowerShell module'

. (Join-Path -Path $PSScriptRoot -ChildPath 'Install-MyModule.ps1')

Install-MyModule `
    -Name 'Microsoft Graph Beta' `
    -Description 'Microsoft Graph Beta PowerShell module'

pwsh.exe -File $MyInvocation.PSCommandPath -Args "-Verbose:$Verbose", '-SkipDependencies'

#endregion Practice: Install Microsoft Graph Beta PowerShell module