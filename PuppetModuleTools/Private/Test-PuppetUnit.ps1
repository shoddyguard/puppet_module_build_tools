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
    $Command = 'pdk test unit 2>&1'
    $PDK_Output = Invoke-Expression $Command
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        $PDK_Output
        throw "PDK unit tests have failed. Exit code: $LASTEXITCODE."
    }
    if (-not($PDK_Output -match "0 failures"))
    {
        $PDK_Output
        throw "PDK unit tests contain failures."
    }
    Write-Verbose "Module unit tests successfully passed"
}