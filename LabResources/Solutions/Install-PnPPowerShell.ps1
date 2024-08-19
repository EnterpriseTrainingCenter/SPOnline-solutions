#Requires -PSEdition Core
#Requires -RunAsAdministrator

. (Join-Path -Path $PSScriptRoot -ChildPath 'Install-MyModule.ps1')

Install-MyModule `
    -Name 'PnP.PowerShell' `
    -Description 'Microsoft 365 Patterns and Practices PowerShell Cmdlets'