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

<# 
    returns -1 if first version is less than second
    0 if versions are equal
    1 if first version is greater than second
#>

function Compare-SemanticVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $FirstVersion,
        [Parameter(Mandatory)]
        [string]
        $SecondVersion
    )


    $firstVersionFirst, $firstVersionRest = $firstVersion -split '\.'
    $secondVersionFirst, $secondVersionRest = $secondVersion  -split '\.'

    $result = 0

    if ($firstVersionFirst -lt $secondVersionFirst) {
        $result = -1
    }

    if ($firstVersionFirst -gt $secondVersionFirst ) {
        $result = 1
    }

    if ($firstVersionFirst -eq $secondVersionFirst) {
        if ($firstVersionRest.Count -and $secondVersionRest.Count) {
            $result = Compare-SemanticVersion `
                -FirstVersion ($firstVersionRest -join '.') `
                -SecondVersion ($secondVersionRest -join '.')
        }
    }

    return $result
}

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
        # The minimum version of the package
        [Parameter()]
        [string]
        $MinimumVersion = '0'
    )

    $appXPackages = Get-AppxPackage -Name $Name |
        Where-Object { $PSItem.Architecture -eq 'x64' }

    if ($appXPackages) {
        foreach ($appXPackage in $appXPackages) {
            $found = $found -or (
                Compare-SemanticVersion `
                    -FirstVersion $appXPackage.Version `
                    -SecondVersion $MinimumVersion
            ) -ge 0
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
    -Description 'WinGet' `
    -MinimumVersion '1.23.1911'

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

$file = (
    Join-Path -Path $PSScriptRoot -ChildPath 'Install-PnPPowwerShell.ps1'
)
pwsh.exe -File $file -Args "-Verbose:$Verbose"

$file = (
    Join-Path -Path $PSScriptRoot -ChildPath 'Install-TeamsAndGraphModule.ps1'
)
pwsh.exe -File $file -Args "-Verbose:$Verbose"

<#
    Install the Teams and Graph modules in the current environment again,
    so scripts can run anyways.
#>

. (Join-Path -Path $PSScriptRoot -ChildPath 'Install-TeamsAndGraphModule.ps1')

$file = (
    Join-Path `
        -Path $PSScriptRoot -ChildPath 'Install-OnlineSharePointModule.ps1'
)
powershell.exe -File $file -Args "-Verbose:$Verbose"

#endregion Task 4: Install PowerShell modules

#endregion Exercise 1: Get started with PowerShell

#region Exercise 2: Manage the SharePoint Administrator role

Write-Host '    Exercise 2: Manage the SharePoint Administrator role'

#region Task 2: Verify the SharePoint Administrator role holders

Write-Host '        Task 2: Verify the SharePoint Administrator role holders'

Write-Verbose '            Sign in to Microsoft Graph'
Write-Warning `
    'In the web browser window, that just opened, sign in with your Office 365 Tenant Credentials for the Global Admin and accept the permissions requests.'
Connect-MgGraph -Scopes 'RoleManagement.ReadWrite.Directory'

Write-Verbose '            Get the SharePoint Administrator role'
$roleName = 'SharePoint Administrator'
$role = Get-MgDirectoryRole -Filter "Displayname eq '$roleName'"

Write-Verbose '            Add role from template if role is not present yet'
if ($null -eq $role) {
    $roleTemplate = Get-MgDirectoryRoleTemplate |
        Where-Object { $PSItem.Displayname -eq $roleName }
    New-MgDirectoryRole `
        -DisplayName $roleName -RoleTemplateId $roleTemplate.Id
    $role = Get-MgDirectoryRole -Filter "Displayname eq '$roleName'"
}

Write-Verbose '            Get the role members and store them in a variable'
$mgDirectoryRoleMember = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
$sharePointAdmins = $mgDirectoryRoleMember | ForEach-Object { Get-MgUser -UserId $PSItem.Id }

#endregion Task 2: Verify the SharePoint Administrator role holders

#region Task 1: Assign the SharePoint Administrator role

Write-Verbose '        Task 1: Assign the SharePoint Administrator role'

$displayname = 'Lynne Robbins'
if ($sharePointAdmins.DisplayName -notcontains $displayname) {
    Write-Verbose `
        '            Find and store the user Lynne Robbins in a variable'
    $mgUser = Get-MgUser -Filter "Displayname eq '$displayname'"
    New-MgDirectoryRoleMemberByRef `
        -DirectoryRoleId $role.Id `
        -OdataId "https://graph.microsoft.com/v1.0/users/$($mgUser.Id)"
}

Write-Verbose '            Disconnect from Microsoft Graph'
Disconnect-Graph

#endregion Exercise 2: Manage the SharePoint Administrator role

#region Exercise 5: Explore SharePoint integration with Teams

Write-Host '    Exercise 5: Explore SharePoint integration with Teams'

#endregion Task 1: Assign the SharePoint Administrator role

#endregion Exercise 5: Explore SharePoint integration with Teams

#endregion Lab: Get started with SharePoint