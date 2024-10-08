@{
    Activities = @(
        @{
            ID = 'GettingStarted'
            DisplayName = 'Lab: Get started with SharePoint'
            Script = 'Start-SharePointAndTeamsConfiguration.ps1'
        }
        @{
            ID = 'InstallVSCode'
            DisplayName = 'Practice: Install Visual Studio Code'
            Script = 'Install-VSCode.ps1'
            DependsOn = 'GettingStarted'
        }
        @{
            ID = 'InstallGraphBeta'
            Displayname = `
                'Practice: Install Microsoft Graph Beta PowerShell module'
            Script = 'Install-GraphBeta.ps1'
            DependsOn = 'GettingStarted'
        }
        @{
            ID = 'SiteAdministration'
            Displayname = 'Lab: Site administration'
            Script = 'New-Sites.ps1'
            DependsOn = 'GettingStarted'
        }
    )
}