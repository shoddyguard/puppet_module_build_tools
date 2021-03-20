<#
.SYNOPSIS
    Tests if a module complies with current PDK defaults
.DESCRIPTION
    Runs a 'pdk convert --noop' as a simple way of checking things need converting
.EXAMPLE
    PS C:\> Test-PuppetModuleConversion
.INPUTS
    ValidExitCodes: which exit codes are expected
#>
function Test-PuppetModuleConversion
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
    $PDK_Output = Invoke-Expression 'pdk convert --noop 2>&1'
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        throw "Convert check failed. Exit code: $LASTEXITCODE."
    }
    if ($PDK_Output -notmatch 'No changes required.')
    {
        throw "Drift detected after running pdk convert. Check convert_report.txt for details."
    }
    Write-Verbose "No drift detected"
}