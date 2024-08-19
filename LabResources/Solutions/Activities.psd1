@{
    Activities = @(
        @{
            ID = 'GettingStarted'
            DisplayName = 'Lab: Get started with SharePoint'
            Script = 'Invoke-SharePointAndTeamsConfiguration.ps1'
        }
        @{
            ID = ''
            DisplayName = ''
            Script = ''
            DependsOn = ''
        }
        @{
            ID = 'InstallVSCode'
            DisplayName = 'Practice: Install Visual Studio Code'
            Script = 'Install-VSCode.ps1'
            DependsOn = 'GettingStarted'
        }
    )
}