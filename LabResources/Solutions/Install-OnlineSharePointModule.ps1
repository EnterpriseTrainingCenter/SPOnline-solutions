#Requires -PSEdition Desktop

. (Join-Path -Path $PSScriptRoot -ChildPath 'Install-MyModule.ps1')

Install-MyModule `
    -Name 'Microsoft.Online.SharePoint.PowerShell' `
    -Description 'Microsoft SharePoint Onine Services'