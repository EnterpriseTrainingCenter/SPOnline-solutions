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

#region Lab: Get started with SharePoint

Write-Host 'Lab: Get started with SharePoint'

#region Exercise 1: Get started with PowerShell

Write-Host '    Exercise 1: Get started with PowerShell'

#region Task 1: Install WinGet

Write-Host '        Task 1: Install WinGet'

Write-Verbose '            Updating the Desktop App Installer'
Install-Script -Name 'Update-InboxApp' -Scope CurrentUser -Force
.\Update-InboxApp.ps1 -PackageFamilyName 'Microsoft.DesktopAppInstaller'

#endregion Task 1: Install WinGet

#region Task 2: Install PowerShell

Write-Host '        Task 2: Install PowerShell'
winget install --id 9MZ1SNWT0N5D --accept-package-agreements --accept-source-agreements --force

#endregion Task 3: Install PowerShell

#region Task 3: Install Windows Terminal

Write-Host '        Task 2: Install Windows Terminal'
winget install --id 9N0DX20HK701 --accept-package-agreements --accept-source-agreements --force

#endregion Task 3: Install Windows Terminal

#region Task 4: Install PowerShell modules

Write-Host '        Task 3: Install PowerShell modules'

$file = (Join-Path -Path $PSScriptRoot -ChildPath 'Install-CoreModules.ps1')
pwsh.exe -File $file

$file = (
    Join-Path `
        -Path $PSScriptRoot -ChildPath 'Install-WindowsPowerShellModules.ps1'
)
powershell.exe -File $file

#endregion Task 4: Install PowerShell modules

#endregion Exercise 1: Get started with PowerShell

#region Exercise 2: Manage the SharePoint Administrator role

Write-Host '    Exercise 2: Manage the SharePoint Administrator role'

$file = (
    Join-Path `
        -Path $PSScriptRoot -ChildPath 'Add-SharePointAdministrator.ps1'
)
pwsh.exe -File $file


#endregion Exercise 2: Manage the SharePoint Administrator role

#region Exercise 5: Explore SharePoint integration with Teams

Write-Host '    Exercise 5: Explore SharePoint integration with Teams'

$file = (
    Join-Path `
        -Path $PSScriptRoot -ChildPath 'New-TeamAndChannels.ps1'
)
pwsh.exe -File $file

#endregion Exercise 5: Explore SharePoint integration with Teams

#endregion Lab: Get started with SharePoint