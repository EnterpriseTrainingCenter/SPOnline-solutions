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
            Write-Verbose "Download package $Description"
    
            Start-BitsTransfer -Source $Source -Destination $destination
        }
    
        Write-Verbose "Install package $Description"
    
        Add-AppxPackage -Path $destination
    }
}

#endregion Helper functions

#region Lab: Get started with SharePoint

Write-Host 'Lab: Get started with SharePoint'

if ($MyInvocation.BoundParameters['Verbose'].IsPresent) {
    $verbose = '-Verbose'
}


#region Exercise 1: Get started with PowerShell

Write-Host '    Exercise 1: Get started with PowerShell'

#region Task 1: Install WinGet

Write-Host '        Task 1: Install WinGet'

if ($PSEdition -eq 'Core') {
    Import-Module -Name Appx -UseWindowsPowerShell
}

if ($PSEdition -eq 'Desktop') {
    Import-Module -Name Appx
}

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

if (-not (Get-AppxPackage -Name 'Microsoft.PowerShell')) {
    Write-Verbose 'Download and install PowerShell'
    winget install --id 9MZ1SNWT0N5D --accept-package-agreements --accept-source-agreements --force
}

#endregion Task 3: Install PowerShell

#region Task 3: Install Windows Terminal

Write-Host '        Task 3: Install Windows Terminal'

if (-not (Get-AppxPackage -Name 'Microsoft.WindowsTerminal')) {
    Write-Verbose 'Download and install Windows Terminal'    
    winget install --id 9N0DX20HK701 --accept-package-agreements --accept-source-agreements --force
}
#endregion Task 3: Install Windows Terminal

#region Task 4: Install PowerShell modules

Write-Host '        Task 4: Install PowerShell modules'

$file = (
    Join-Path -Path $PSScriptRoot -ChildPath 'Install-PnPPowerShell.ps1'
)
pwsh.exe -File $file $verbose

$file = (
    Join-Path `
        -Path $PSScriptRoot -ChildPath 'Install-OnlineSharePointModule.ps1'
)
powershell.exe -File $file $verbose

$file = (
    Join-Path `
        -Path $PSScriptRoot -ChildPath 'Install-TeamsExchangeAndGraphModule.ps1'
)
powershell.exe -File $file $verbose


#endregion Task 4: Install PowerShell modules

#region Task 5: Verify the functionality of the PowerShell modules

Write-Host '        Task 5: Verify the functionality of the PowerShell modules'

Write-Verbose 'Import the modules'
Import-Module Microsoft.Graph
Import-Module MicrosoftTeams # Always last

#endregion Exercise 1: Get started with PowerShell

#region Exercise 2: Manage the SharePoint Administrator role

Write-Host '    Exercise 2: Manage the SharePoint Administrator role'

#region Task 2: Verify the SharePoint Administrator role holders

Write-Host '        Task 2: Verify the SharePoint Administrator role holders'

Write-Verbose 'Sign in to Microsoft Graph'
Write-Warning `
    'In the web browser window, that just opened, sign in with your Office 365 Tenant Credentials for the Global Admin and accept the permissions requests.'
Connect-MgGraph -Scopes 'RoleManagement.ReadWrite.Directory' -NoWelcome

Write-Verbose 'Get the SharePoint Administrator role'
$roleName = 'SharePoint Administrator'
$role = Get-MgDirectoryRole -Filter "Displayname eq '$roleName'"

if ($null -eq $role) {
    Write-Verbose 'Add role from template'
    $roleTemplate = Get-MgDirectoryRoleTemplate |
        Where-Object { $PSItem.Displayname -eq $roleName }
    New-MgDirectoryRole `
        -DisplayName $roleName -RoleTemplateId $roleTemplate.Id
    $role = Get-MgDirectoryRole -Filter "Displayname eq '$roleName'"
}

Write-Verbose 'Get the role members and store them in a variable'
$mgDirectoryRoleMember = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
$sharePointAdmins = $mgDirectoryRoleMember | ForEach-Object { Get-MgUser -UserId $PSItem.Id }

#endregion Task 2: Verify the SharePoint Administrator role holders

#region Task 1: Assign the SharePoint Administrator role

Write-Host '        Task 1: Assign the SharePoint Administrator role'

$displayname = 'Lynne Robbins'
if ($sharePointAdmins.DisplayName -notcontains $displayname) {
    Write-Verbose `
        '            Find and store the user Lynne Robbins in a variable'
    $mgUser = Get-MgUser -Filter "Displayname eq '$displayname'"

    Write-Verbose 'Add the stored user to the role'
    New-MgDirectoryRoleMemberByRef `
        -DirectoryRoleId $role.Id `
        -OdataId "https://graph.microsoft.com/v1.0/users/$($mgUser.Id)"
}

#endregion Task 1: Assign the SharePoint Administrator role

#endregion Exercise 2: Manage the SharePoint Administrator role

#region Exercise 5: Explore SharePoint integration with Teams

Write-Host '    Exercise 5: Explore SharePoint integration with Teams'

#region Task 1: Create a new team

Write-Host '        Task 1: Create a new team'

Write-Verbose 'Sign in to Microsoft Teams'
Write-Warning `
    'In the web browser window, that just opened, sign in with your Office 365 Tenant Credentials for the Global Admin.'
$null = Connect-MicrosoftTeams

$displayname = 'SharePoint Project'
$ownerDisplayname = 'Lynne Robbins'
$owner = (Get-MgUser -Filter "Displayname eq '$ownerDisplayname'").UserPrincipalName
$team = Get-Team -DisplayName $displayname
if (-not $team) {
    Write-Verbose "Create a team with the name $displayname"
    $ownerDisplayname = 'Lynne Robbins'
    $owner = (Get-MgUser -Filter "Displayname eq '$ownerDisplayname'").UserPrincipalName
    $team = New-Team `
        -DisplayName 'SharePoint Project' `
        -MailNickName 'SharePointProject' `
        -Owner $owner
}

$displayname = 'Megan Bowen'
if (($team | Get-TeamUser).Name -notcontains $displayname) {
    Write-Verbose "Add $displayname to the team"
    $mgUser = Get-MgUser -Filter "Displayname eq '$displayname'"
    $team | Add-TeamUser -User $mgUser.UserPrincipalName
}

#endregion Task 1: Create a new team

#region Task 2: Create a standard channel

Write-Host '        Task 2: Create a standard channel'

$displayname = 'Planning'
if (($team | Get-TeamChannel).DisplayName -notcontains $displayname) {
    Write-Verbose `
        "            Create a standard channel with the name $displayname"
    $null = $team |
        New-TeamChannel -DisplayName $displayname -MembershipType Standard
}

#endregion Task 2: Create a standard channel

#region Task 4: Create a shared channel

Write-Host '        Task 4: Create a shared channel'

$displayname = 'Governance'
if (($team | Get-TeamChannel).DisplayName -notcontains $displayname) {
        Write-Verbose `
        "            Create a shared channel with the name $displayname"
    $null = $team |
        New-TeamChannel `
            -DisplayName $displayname -MembershipType Shared -Owner $owner
    # We have to wait a few seconds for the channel to be created
    Start-Sleep -Seconds 10
}

$name = 'Patti Fernandez'
if (
    (
        $team | Get-TeamChannelUser -DisplayName $displayname
    ).Name -notcontains $name
) {
    Write-Verbose "Add $name to the shared channel"
    $user = (Get-MgUser -Filter "Displayname eq '$name'").UserPrincipalName
    $team | Add-TeamChannelUser -DisplayName $displayname -User $user
}

#endregion Task 4: Create a standard channel

Write-Verbose 'Disconnect from Microsoft Teams'

#endregion Exercise 5: Explore SharePoint integration with Teams

Write-Verbose 'Disconnect from Microsoft Graph'
$null = Disconnect-Graph

#endregion Lab: Get started with SharePoint