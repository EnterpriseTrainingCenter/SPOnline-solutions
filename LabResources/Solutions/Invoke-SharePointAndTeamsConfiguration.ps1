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

#region Helper function

function Install-AppxPackage {
    [CmdletBinding()]
    param (
        # Name of Appx package
        [Parameter(Mandatory)]
        [string]
        $Name,
        # Download url for package
        [Parameter(Mandatory)]
        [string]
        $Source,
        # Filename of downloaded package
        [Parameter(Mandatory)]
        [string]
        $Filename,
        # Description of package
        [Parameter()]
        [string]
        $Description = $Name,
        # Minimum version of package
        [Parameter()]
        [string]
        $MinimumVersion = '0.0.0'
    )

    $splitMinimumVersion = $MinimumVersion -split '\.'
    $found = $false
    $appXPackages = Get-AppxPackage -Name $Name |
        Where-Object { $PSItem.Architecture -eq 'x64' }

    if ($appXPackage) {
        foreach ($appXPackage in $appXPackages) {
            $version = $appXPackage.Version -split '\.'
            $found = $version[0] -gt $splitMinimumVersion[0]
            $found = $found -or (
                $version[0] -eq $splitMinimumVersion[0] -and `
                $version[1] -gt $splitMinimumVersion[1]
            )
            $found = $found -or (
                $version[0] -eq $splitMinimumVersion[0] -and `
                $version[1] -eq $splitMinimumVersion[1] -and `
                $version[2] -ge $splitMinimumVersion[2]
            )
        }
    }

    if (-not $found) {
        $destination = "~\Downloads\$Filename"
    
        if (-not (Test-Path -Path $destination)) {
            Write-Verbose "            Download package $Description"
    
            Start-BitsTransfer -Source $Source -Destination $destination
        }
    
        Write-Verbose "            Install package $Description"
    
        Add-AppxPackage -Path $destination
    }
}

#endregion Helper functions

#region Lab: Get started with SharePoint

Write-Host 'Lab: Get started with SharePoint'

#region Exercise 1: Get started with PowerShell

Write-Host '    Exercise 1: Get started with PowerShell'

#region Task 1: Install WinGet

Write-Host '        Task 1: Install WinGet'

Install-AppxPackage `
    -Name 'Microsoft.VCLibs.140.00' `
    -Source 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' `
    -Filename 'Microsoft.VCLibs.x64.14.00.Desktop.appx' `
    -Description 'Microsoft Visual C++ 2015 Redistributable'
Install-AppxPackage `
    -Name 'Microsoft.UI.Xaml.2.8' `
    -Source `
        'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' `
    -Filename 'Microsoft.UI.Xaml.2.8.x64.appx' `
    -Description 'WinUI3'
Install-AppxPackage `
    -Name 'Microsoft.DesktopAppInstaller' `
    -Source 'https://aka.ms/getwinget' `
    -Filename 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' `
    -Description 'WinGet'

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
powershell.exe -File $file


#endregion Exercise 2: Manage the SharePoint Administrator role

#region Exercise 5: Explore SharePoint integration with Teams

Write-Host '    Exercise 5: Explore SharePoint integration with Teams'

$file = (
    Join-Path `
        -Path $PSScriptRoot -ChildPath 'New-TeamAndChannels.ps1'
)
powershell.exe -File $file

#endregion Exercise 5: Explore SharePoint integration with Teams

#endregion Lab: Get started with SharePoint