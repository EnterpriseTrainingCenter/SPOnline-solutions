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

#region helper functions

function New-Site {
    [CmdletBinding()]
    param (
        # Url of the site
        [Parameter(Mandatory)]
        [String]
        $Url,
        # Site template for the site
        [Parameter(Mandatory)]
        [string]
        $Template,
        # Owner of the site
        [Parameter(Mandatory)]
        [string]
        $Owner,
        # Title of the site
        [Parameter()]
        [string]
        $Title
    )

    $sPOSite = Get-SPOSite -Filter "Url -eq '$Url'"

    # Check site template

    if (($null -ne $sPOSite) -and ($sPOSite.Template -ne $Template)) {
        Write-Warning `
            "Site at $Url was not created with the correct template. Delete site."
        Remove-SPOSite -Identity $Url
        $sPOSite = $null
    }

    # Remove deleted site

    if (
        $null -ne (
            Get-SPODeletedSite -Identity $url -ErrorAction SilentlyContinue
        )
    ) {
        Write-Warning "Permanently delete deleted site at $URL"
        Remove-SPODeletedSite -Identity $Url -Confirm:$false
    }

    #Create site

    if ($null -eq $sPOSite) {
        Write-Verbose "Create site $Title at $Url"
        New-SPOSite `
            -Url $Url `
            -Template $Template `
            -Owner $Owner `
            -LocaleId 1033 `
            -Title $Title `
            -StorageQuota 26214400
            $sPOSite = Get-SPOSite -Identity $Url
    }

    # Configure owner

    if ($sPOSite.Owner -ne $Owner) {
        Write-Verbose "Set owner to $Owner for site $Url"
        Set-SPOSite -Identity $Url -Owner $Owner
    }

    return $sPOSite
}

#endregion helper functions

Write-Host 'Lab: Site administration'

#region Exercise 1: Manage sites

Write-Host '    Exercise 1: Manage sites'

$sites = @{
    ITInternal = @{
        Title = 'IT department internal'
        Url = 'IT-internal'
    }
    Project1Drive = @{
        Title = 'OneDrive deployment project'
        Url = 'Project1Drive'
    }
    PlaygroundSite = @{
        Title = 'SharePoint playground'
        Url = 'SharePoint-Playground'
    }
    IT = @{
        Title = 'IT department'
        Url = 'IT'
    }
    Home = @{
        Title = 'Contoso home'
        Url = 'home'
    }
    Helpdesk = @{
        Title = 'IT help desk'
        Url = 'IThelpdesk'
    }
}

#region Task 1: Create a team site with a Microsoft 365 Group

Write-Host '        Task 1: Create a team site with a Microsoft 365 Group'
Import-Module Microsoft.Graph.Authentication
Write-Verbose 'Sign in to Microsoft Graph'
Write-Warning `
    'In the web browser window, that just opened, sign in with your Office 365 Tenant Credentials for the Global Admin and accept the permissions requests.'
Connect-MgGraph -Scopes Domain.Read.All

Write-Verbose 'Get the initial domain name'
Import-Module Microsoft.Graph.Identity.DirectoryManagement
$initialDomain = Get-MgDomain | Where-Object { $PSItem.IsInitial }
$tenantName = ($initialDomain.Id -split '\.') | Select-Object -First 1

Write-Verbose 'Get user Lynne Robbins'
Import-Module Microsoft.Graph.Users
$owner = (Get-MgUser -Filter "Displayname eq 'Lynne Robbins'").UserPrincipalName

Write-Verbose 'Sign in to SharePoint Online'
if ($PSEdition -eq 'Core') {
    Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell
}
if ($PSEdition -eq 'Desktop') {
    Import-Module Microsoft.Online.SharePoint.PowerShell
}
Write-Warning `
    'In the web browser window, that just opened, sign in with your Office 365 Tenant Credentials for the Global Admin.'
Connect-SPOService -Url "https://$tenantName-admin.sharepoint.com"
$sPOSite = New-Site `
    -Url "https://$tenantName.sharepoint.com/sites/$($sites.ITInternal.Url)" `
    -Template 'STS#3' `
    -Owner "admin@$($initialDomain.Id)" `
    -Title $sites.ITInternal.Title

$alias = 'IT'
if ($sPOSite.GroupId.Guid -eq '00000000-0000-0000-0000-000000000000') {
    Write-Verbose 'Connect site with Microsoft 365 group'
    Set-SPOSiteOffice365Group `
        -Site $sPOSite.Url -DisplayName $sites.ITInternal.Title -Alias $alias
}

Write-Verbose 'Sign in to Exchange Online'
Import-Module ExchangeOnlineManagement
Write-Warning `
    'In the web browser window, that just opened, sign in with your Office 365 Tenant Credentials for the Global Admin.'
Connect-ExchangeOnline

$unifiedGroupLinks = Get-UnifiedGroupLinks -Identity $alias -LinkType Owners
$links = $unifiedGroupLinks | Where-Object {$PSItem -notin @($owner) }
if ($links) {
    Write-Verbose 'Remove owners'
    Remove-UnifiedGroupLinks -Identity $alias -LinkType Owners -Links $links
}
$links = @($owner) | Where-Object { $PSItem -notin $unifiedGroupLinks }
if ($links) {
    Write-Verbose 'Add owners'
    Add-UnifiedGroupLinks -Identity $alias -LinkType Owners -Links $links
}

Write-Verbose 'Build a list of users to be added to the group'
$members = @(
    'Miriam Graham'
    'Alex Wilber'
    'Christie Cline'
    'Isaiah Langer'
    'Megan Bowen'
    'Adele Vance'
    'Debra Berger'
    'Nestor Wilke'
    'Lee Gu'
    'Joni Sherman'
    'Pradeep Gupta'
) | ForEach-Object { 
    (Get-MgUser -Filter "Displayname eq '$PSItem'").UserPrincipalName 
}
$unifiedGroupLinks = Get-UnifiedGroupLinks -Identity $alias -LinkType Members

$links = $members | 
    Where-Object { $PSItem -notin $unifiedGroupLinks.WindowsLiveId }
if ($links) {
    Write-Verbose 'Add the users to the group'
    Add-UnifiedGroupLinks -Identity $alias -LinkType Members -Links $links
}

#endregion Task 1: Create a team site with a Microsoft 365 Group

#region Task 2: Create team sites without a Microsoft 365 group

Write-Host '        Task 2: Create team sites without a Microsoft 365 group'

$site = $sites.Project1Drive
$null = New-Site `
    -Url "https://$tenantName.sharepoint.com/sites/$($site.Url)" `
    -Template 'STS#3' `
    -Owner $owner `
    -Title $site.Title


# Create Playground site only, if it does not exist under old and new url

$site = $sites.PlaygroundSite
$url = "https://$tenantName.sharepoint.com/sites/PlaygroundSite" 
if (-not(Get-SPOSite -Filter "Url -eq '$url'")) {
    $null = New-Site `
        -Url "https://$tenantName.sharepoint.com/sites/$($site.Url)" `
        -Template 'STS#3' `
        -Owner $owner `
        -Title $site.Title
}

#endregion Task 2: Create team sites without a Microsoft 365 group

#region Task 3: Create communication sites

Write-Host '        Task 3: Create communication sites'
$sites.IT, $sites.Home |
ForEach-Object {
    $null = New-Site `
        -Url "https://$tenantName.sharepoint.com/sites/$($PSItem.Url)" `
        -Template 'SITEPAGEPUBLISHING#0' `
        -Owner $owner `
        -Title $PSItem.Title `
}

#endregion Task 3: Create communication sites

#region Task 4: Connect a team site to a new Microsoft 365 group

Write-Host '        Task 4: Connect a team site to a new Microsoft 365 group'

$sPOSite = Get-SPOSite -Filter "Url -eq 'https://$tenantName.sharepoint.com/sites/$($sites.Project1Drive.Url)'"

if ($sPOSite.GroupId.Guid -eq '00000000-0000-0000-0000-000000000000') {
    Write-Verbose 'Take ownership of site'
    Set-SPOSite -Identity $sPOSite.Url -Owner "admin@$($initialDomain.Id)"
    
    Write-Verbose 'Connect site with Microsoft 365 group'
    Set-SPOSiteOffice365Group `
        -Site $sPOSite.Url -DisplayName $sites.Project1Drive.Title -Alias 'Project1Drive'
    
    Write-Verbose 'Give ownership back'
    Set-SPOSite -Identity $sPOSite.Url -Owner $owner
}


#endregion Task 4: Connect a team site to a new Microsoft 365 group

#region Task 5: Upgrade a Microsoft 365 group to a team
Write-Host "        Task 5: Upgrade a Microsoft 365 group to a team"

Write-Verbose "Retrieve the Microsoft 365 group $($sites.Project1Drive.Title)"
$sPOSite = Get-SPOSite -Filter "Url -eq 'https://$tenantName.sharepoint.com/sites/$($sites.Project1Drive.Url)'"


if (-not $sPOSite.IsTeamsConnected) {
    Write-Verbose 'Connect to Microsoft Teams'
    Import-Module MicrosoftTeams
    Write-Warning `
        'In the web browser window, that just opened, sign in with your Office 365 Tenant Credentials for the Global Admin.'
    Connect-MicrosoftTeams

    Write-Verbose 'Add the Teams functionality to the group'
    $null = New-Team -GroupId $sPOSite.GroupId.Guid

    Write-Verbose 'Disconnect from Microsoft Teams'
    Disconnect-MicrosoftTeams
}

#endregion Task 5: Upgrade a Microsoft 365 group to a team

#endregion Exercise 1: Manage sites

#region Exercise 2: Manage site admins

Write-Host '    Exercise 2: Manage site admins'

#region Task 1: Add a site admins to a site

Write-Host '        Task 1: Add a site admins to a site'

$loginName = `
    (Get-MgUser -Filter "Displayname eq 'Joni Sherman'").UserPrincipalName

$url = "https://$tenantName.sharepoint.com/sites/$($sites.Home.Url)"

Write-Verbose 'Take ownership of site'
$sPOSite = Get-SPOSite -Identity $url
$owner = $sPOSite.Owner
Set-SPOSite -Identity $url -Owner "admin@$tenantName.onmicrosoft.com"

$sPOUser = Get-SPOUser `
    -Site $url -LoginName $loginName -ErrorAction SilentlyContinue
if ($null -eq $sPOUser -or -not $sPOUser.IsSiteAdmin) {
    Write-Verbose 'Add the user as site admin'
    Set-SPOUser -Site $url -LoginName $loginName -IsSiteCollectionAdmin $true
}

Write-Verbose 'Give back ownership of site'
Set-SPOSite -Identity $url -Owner $owner

#endregion Task 1: Add a site admins to a site

#endregion Exercise 2: Manage site admins

#region Exercise 3: Manage site creation

Write-Host '    Exercise 3: Manage site creation'

#region Task 1: Verify that users can create Microsoft 365 groups

Write-Host '        Task 1: Verify that users can create Microsoft 365 groups'

Write-Verbose 'Get user Joni Sherman'
Import-Module Microsoft.Graph.Users
$owner = (Get-MgUser -Filter "Displayname eq 'Joni Sherman'").UserPrincipalName

$jonisGroupDisplayName = 'Jonis''s group'
if (-not (
    Get-UnifiedGroup -Filter "Displayname -eq '$(
        $jonisGroupDisplayName -replace '''', ''''''
    )'"
)) {
    Write-Verbose 'Create Joni''s group'
    New-UnifiedGroup `
        -DisplayName $jonisGroupDisplayName -Alias "jonisgroup" -Owner $owner
}


#endregion Task 1: Verify that users can create Microsoft 365 groups

#region Task 2: Limit the users that can create Microsoft 365 groups

Write-Host `
    '        Task 2: Limit the users that can create Microsoft 365 groups'

Write-Verbose 'Disconnect from graph and remove all modules from memory'
$null = Disconnect-MgGraph
Get-Module -Name Microsoft.Graph.* | Remove-Module -Force

# Write-Verbose 'Connect to Graph Beta'
Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Beta.Groups

Connect-MgGraph -Scopes "Directory.ReadWrite.All", "Group.Read.All"
Write-Warning `
    'In the web browser window, that just opened, sign in with your Office 365 Tenant Credentials for the Global Admin and accept the permissions requests.'

$groupName = "sg-IT"
$allowGroupCreation = "False"

Write-Verbose 'Retrieve directory setting object'
$settingsObjectID = (
    Get-MgBetaDirectorySetting |
    Where-Object -Property Displayname -Value "Group.Unified" -EQ
).Id

if($null -eq $settingsObjectID)
{
    Write-Verbose 'Create directory settings object'
    $params = @{
        templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b"
        values = @(@{
            name = "EnableMSStandardBlockedWords"
            value = "true"
        })
    }
    New-MgBetaDirectorySetting -BodyParameter $params
    $settingsObjectID = (
        Get-MgBetaDirectorySetting | 
        Where-Object -Property Displayname -Value "Group.Unified" -EQ
    ).Id
}

Write-Verbose 'Get the Group'
$groupId = `
    (Get-MgBetaGroup | Where-object {$PSItem.displayname -eq $groupName}).Id

$params = @{
    templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b"
    values = @(
        @{
            name = "EnableGroupCreation"
            value = $allowGroupCreation
        }
        @{
            name = "GroupCreationAllowedGroupId"
            value = $groupId
        }
    )
}

Write-Verbose 'Update the directory settings object'
Update-MgBetaDirectorySetting `
    -DirectorySettingId $settingsObjectID -BodyParameter $params

Write-Verbose 'Disconnect from Graph and remove beta modules'
$null = Disconnect-MgGraph
Get-Module -Name Microsoft.Graph.Beta.* | Remove-Module -Force

# (Get-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID).Values

#endregion Task 2: Limit the users that can create Microsoft 365 groups

#region Task 4: Verify that users can create SharePoint sites

Write-Host '        Task 4: Verify that users can create SharePoint sites'

$site = $sites.Helpdesk
$null = New-Site `
    -Url "https://$tenantName.sharepoint.com/sites/$($site.Url)" `
    -Template 'STS#3' `
    -Owner $owner `
    -Title $site.Title

#endregion Task 4: Verify that users can create SharePoint sites

#region Task 5: Change settings for site creation

Write-Host '        Task 5: Change settings for site creation'
Set-SPOTenant -SelfServiceSiteCreationDisabled $true

#endregion Task 5: Change settings for site creation

#endregion Exercise 3: Manage site creation

#region Exercise 4: Manage storage limits

Write-Host '    Exercise 4: Manage storage limits'

#region Task 1: Change the site storage limits to manual

Write-Warning @'
This task cannot be accomplished using PowerShell at the moment.
Please refer to the lab guide to perform this task manually.
'@

#endregion Task 1: Change the site storage limits to manual

#region Task 2: Change the storage limits of sites

Write-Host '        Task 2: Change the storage limits of sites'

Write-Verbose @"
    Set the storage limit of the site $($sites.IT.Title) to 1 GB and 
    the warning level to 97 % of the storage limit.
"@
$storageQuota = 1024
Set-SPOSite `
    -Identity https://$tenantName.sharepoint.com/sites/$($sites.IT.Url) `
    -StorageQuota $storageQuota `
    -StorageQuotaWarningLevel ($storageQuota * .97)

#endregion Task 2: Change the storage limits of sites

#endregion Exercise 4: Manage storage limits

#region Exercise 5: Change a site address

Write-Host '    Exercise 5: Change a site address'

#region Task 1: Change the address of a site

Write-Host '        Task 1: Change the address of a site'

$identity = "https://$tenantName.sharepoint.com/sites/PlaygroundSite"
$newSiteUrl = `
    "https://$tenantName.sharepoint.com/sites/$($sites.PlaygroundSite.Url)"

if (-not (Get-SPOSite -Filter "Url -eq '$newSiteUrl'")) {
    Write-Verbose "Start the site rename of the site $identity to $newSiteUrl"
    Start-SPOSiteRename `
        -Identity $identity -NewSiteUrl $newSiteUrl
}


#endregion Task 1: Change the address of a site

#endregion Exercise 5: Change a site address

#region Exercise 8: Manage lock states

Write-Host '    Exercise 8: Manage lock states'

#region Task 2: Set the tenant's unavailability page

Write-Host '        Task 2: Set the tenant''s unavailability page'
Write-Warning `
    'The redirect URL can vary. Therefore, please refer to the lab guide for this task.'

#endregion Task 2: Set the tenant's unavailability page

#region Task 3: Make a site unavailable

Write-Host '        Task 3: Make a site unavailable'

Write-Verbose 'Make Joni''s site unavailable'
$sPOSite = Get-SPOSite |
    Where-Object { $PSItem.Title -eq $jonisGroupDisplayName }
$sPOSite | Set-SPOSite -LockState NoAccess

#endregion Task 3: Make a site unavailable

#region Task 5: Make a site read-only

Write-Host '        Task 5: Make a site read-only'

Write-Verbose 'Make the OneDrive deployment project site read-only'
Set-SPOSite `
    -Identity `
        "https://$tenantName.sharepoint.com/sites/$($sites.Project1Drive.Url)" `
        -LockState ReadOnly

#endregion Task 5: Make a site read-only
#endregion Exercise 8: Manage lock states

Write-Verbose 'Disconnect from Exchange, SharePoint, and Microsoft Graph'
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-SPOService
