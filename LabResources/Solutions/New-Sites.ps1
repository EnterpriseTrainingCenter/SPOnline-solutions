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

Write-Host 'Lab: Site administration'

#region Exercise 1: Manage sites

Write-Host '    Exercise 1: Manage sites'

#region Task 1: Create a team site with a Microsoft 365 Group

Write-Host '        Task 1: Create a team site with a Microsoft 365 Group'

#endregion Task 1: Create a team site with a Microsoft 365 Group

#endregion Exercise 1: Manage sites

#region Exercise 2: Manage site admins
#endregion Exercise 2: Manage site admins

#region Exercise 3: Manage site creation
#endregion Exercise 3: Manage site creation

#region Exercise 4: Manage storage limits
#endregion Exercise 4: Manage storage limits

#region Exercise 5: Change a site address
#endregion Exercise 5: Change a site address

#region Exercise 6: Replace the root site
#region Exercise 6: Replace the root site

#region Exercise 7: Manage hub sites
#endregion Exercise 7: Manage hub sites

#region Exercise 8: Manage lock states
#endregion Exercise 8: Manage lock states