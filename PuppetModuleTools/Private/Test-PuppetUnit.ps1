<#
.SYNOPSIS
    Runs unit tests against a Puppet module
.DESCRIPTION
    Runs 'pdk test unit' against a Puppet module
.EXAMPLE
    PS C:\> Test-PuppetUnit
.INPUTS
    ValidExitCodes: the expected exit codes from PDK
#>
function Test-PuppetUnit
{
    [CmdletBinding()]
    param
    (
        # The expected exit codes
        [Parameter(Mandatory = $false)]
        [array]
        $ValidExitCodes = @(0)
    )
    $PDK_Output = Invoke-Expression 'pdk test unit 2>&1'
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        throw "PDK unit tests have failed. Exit code: $LASTEXITCODE."
    }
    if (-not($PDK_Output -match "0 failures"))
    {
        throw "PDK unit tests contain failures."
    }
    Write-Verbose "Module unit tests successfully passed"
}