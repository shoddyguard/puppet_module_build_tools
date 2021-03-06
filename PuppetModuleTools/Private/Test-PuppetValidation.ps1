<#
.SYNOPSIS
    Tests that a Puppet module passes validation
.DESCRIPTION
    Runs a 'pdk validate' test while redirecting stdout/stderr to enable checking for warnings.
.EXAMPLE
    PS C:\myModule> Test-PuppetValidation
    Tests the validation on the module at c:\myModule
.INPUTS
    ValidExitCodes: the expected exit codes of the process
    FailOnWarning: whether or not to fail on warnings
#>
function Test-PuppetValidation
{
    [CmdletBinding()]
    param(

        # The codes you expect PDK to return on a successful run
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Array]
        $ValidExitCodes = @(0),


        # If set to true will fail if the validation contains warnings
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [bool]
        $FailOnWarning = $true
    )
    $Command = 'pdk validate 2>&1'
    $Validation = Invoke-Expression $Command
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        $Validation
        throw "Puppet module validation has failed. Exit code: $($LASTEXITCODE)."
    }
    $Warnings = $Validation -match 'pdk \(WARNING\)'
    if (($Warnings) -and ($FailOnWarning -eq $true))
    {
        $Warnings
        throw "Puppet module validation contains warnings."
    }
    Write-Verbose "Puppet module successfully passed validation"
}