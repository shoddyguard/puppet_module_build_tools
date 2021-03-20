function Test-PuppetUnit
{
    [CmdletBinding()]
    param
    (
        # The expected exit codes
        [Parameter(Mandatory = $false)]
        [array]
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
    $PDK_Output = Invoke-Expression 'pdk test unit'
    Pop-Location
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        throw "PDK unit tests have failed. Exit code: $LASTEXITCODE.`n$PDK_Output"
    }
    if (-not($PDK_Output -match "0 failures"))
    {
        throw "PDK unit tests contain failures.`n$PDK_Output"
    }
    Write-Host "Module unit tests successfully passed" -ForegroundColor Green
}