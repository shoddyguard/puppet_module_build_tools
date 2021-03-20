<#
.SYNOPSIS
    Tests if a module complies with PDK defaults
.DESCRIPTION
    Runs a 'pdk convert --noop' as a simple way of checking things need converting
.EXAMPLE
    PS C:\> Test-PuppetModuleConversion
.INPUTS
    ValidExitCodes: which exit codes are expected
    ModulePath: the path to the module to test against
#>
function Test-PuppetModuleConversion
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
    $PDK_Output = Invoke-Expression 'pdk convert --noop'
    Pop-Location
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        throw "Convert check failed. Exit code: $LASTEXITCODE."
    }
    if ($PDK_Output -notmatch 'No changes required.')
    {
        throw "Drift detected after running pdk convert. Check convert_report.txt for details."
    }
    Write-Host "No drift detected" -ForegroundColor Green
}