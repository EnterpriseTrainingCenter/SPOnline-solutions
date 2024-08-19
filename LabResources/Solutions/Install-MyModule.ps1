function Install-MyModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,
        # Description of module
        [Parameter()]
        [string]
        $Description = $Name
    )

    if (-not (Get-Module -Name $Name -ListAvailable)) {
        Write-Verbose "Install module $Description"
        Install-Module -Name $Name -Scope CurrentUser -AllowClobber -Force
    }
}