[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $SkipDependencies,
    [Parameter()]
    [switch]
    $NoRecursion
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

if (-not $NoRecursion) {
    Write-Host 'Practice: Install Microsoft Graph Beta PowerShell module'
}

. (Join-Path -Path $PSScriptRoot -ChildPath 'Install-MyModule.ps1')

if (-not $NoRecursion) {
    $file = $MyInvocation.MyCommand.Path
    if ($MyInvocation.BoundParameters['Verbose'].IsPresent) {
        $verbose = '-Verbose'
    }
    pwsh.exe -File $file -SkipDependencies -NoRecursion $verbose
}

Install-MyModule `
    -Name 'Microsoft.Graph.Beta' `
    -Description 'Microsoft Graph Beta PowerShell module'

#endregion Practice: Install Microsoft Graph Beta PowerShell module