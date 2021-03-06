<#
.SYNOPSIS
    Tests if a module can be updated
.DESCRIPTION
    Runs a 'pdk update --noop' as a simple way of checking things conform to the latest standards.
.EXAMPLE
    PS C:\> Test-PuppetModuleUpdate
.INPUTS
    ValidExitCodes: which exit codes are expected
#>
function Test-PuppetModuleUpdate
{
    [CmdletBinding()]
    param
    (
        # The codes you expect PDK to return on a successful run
        [Parameter(Mandatory = $false)]
        [Array]
        $ValidExitCodes = @(0)
    )
    # Perform a noop to be safe
    $Command = 'pdk update --noop 2>&1'
    $PDK_Output = Invoke-Expression $Command
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        $PDK_Output
        throw "Update check failed. Exit code: $LASTEXITCODE."
    }
    if ($PDK_Output -notmatch 'No changes required.')
    {
        throw "Puppet module can be updated. Check update_report.txt in the module root for details."
    }
    Write-Verbose "Module up-to-date"
}