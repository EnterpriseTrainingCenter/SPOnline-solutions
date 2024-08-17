#Requires -PSEdition Core

. (Join-Path -Path $PSScriptRoot -ChildPath 'Install-MyModule.ps1')

Install-MyModule `
    -Name 'PnP.PowerShell' `
    -Description 'Microsoft 365 Patterns and Practices PowerShell Cmdlets'

Install-MyModule -Name 'MicrosoftTeams' -Description 'Microsoft Teams cmdlets'

Install-MyModule -Name 'Microsoft.Graph' -Description 'Microsoft Graph'