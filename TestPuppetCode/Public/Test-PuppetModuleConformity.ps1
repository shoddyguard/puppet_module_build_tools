<#
.SYNOPSIS
    Tests if a module complies with PDK defaults
.DESCRIPTION
    Runs a 'pdk convert --noop' as a simple way of checking things conform to the latest standards.
.EXAMPLE
    PS C:\> Test-PuppetModuleConformity
.INPUTS
    Command: the command to be run (defaults to 'pdk convert --noop)
    ValidExitCodes: which exit codes are expected
#>
function Test-PuppetModuleConformity
{
    [CmdletBinding()]
    param
    (
        # The command to run
        [Parameter(Mandatory = $false)]
        [string]
        $CommandToExecute = "pdk convert --noop",

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
    $PDK_Output = Invoke-Expression $CommandToExecute
    Pop-Location
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        throw "Command '$CommandToExecute' failed. Exit code: $LASTEXITCODE."
    }
    if ($PDK_Output -notmatch 'No changes required.')
    {
        throw "Drift detected on $CommandToExecute. Check report.txt."
    }
    Write-Host "No drift detected" -ForegroundColor Green
}