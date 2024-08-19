. (Join-Path -Path $PSScriptRoot -ChildPath 'Install-MyModule.ps1')

Install-MyModule `
    -Name 'ExchangeOnlineManagement' `
    -Description 'Exchange Online PowerShell V3'

Install-MyModule -Name 'MicrosoftTeams' -Description 'Microsoft Teams cmdlets'

Install-MyModule -Name 'Microsoft.Graph' -Description 'Microsoft Graph'