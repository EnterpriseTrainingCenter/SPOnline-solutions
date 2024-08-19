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

#region Practice: Install Visual Studio Code

Write-Host 'Practice: Install Visual Studio Code'

if (-not (
    Get-ItemProperty `
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' |
    Where-Object { 
        $PSItem.DisplayName -eq 'Microsoft Visual Studio Code (User)' 
    }
)) {
    Write-Verbose '            Download and install Microsoft Visual Studio Code'
    winget install --id XP9KHM4BK9FZ7Q --accept-package-agreements --accept-source-agreements --force
}

#endregion Practice: Install Visual Studio Code