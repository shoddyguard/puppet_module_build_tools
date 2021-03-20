<#
.SYNOPSIS
    Tests if a module can be updated
.DESCRIPTION
    Runs a 'pdk update --noop' as a simple way of checking things conform to the latest standards.
.EXAMPLE
    PS C:\> Test-PuppetModuleUpdate
.INPUTS
    ValidExitCodes: which exit codes are expected
    ModulePath: the path to the Puppet module to test
#>
function Test-PuppetModuleUpdate
{
    [CmdletBinding()]
    param
    (

        # The codes you expect PDK to return on a successful run
        [Parameter(Mandatory = $false)]
        [Array]
        $ValidExitCodes = @(0),

        # The path to the module to test against
        [Parameter(Mandatory = $false)]
        [string]
        $ModulePath = $env:PuppetModuleRoot
    )
    try
    {
        Push-Location -Path $ModulePath -ErrorAction Stop
    }
    catch
    {
        throw "Failed to move into Puppet module path"
    }
    # Perform a noop to be safe
    $PDK_Output = Invoke-Expression 'pdk update --noop'
    Pop-Location
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        throw "Update check failed. Exit code: $LASTEXITCODE."
    }
    if ($PDK_Output -notmatch 'No changes required.')
    {
        throw "Puppet module can be updated. Check update_report.txt for details."
    }
    Write-Host "Module up-to-date" -ForegroundColor Green
}