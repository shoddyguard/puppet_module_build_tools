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
    try
    {
        Push-Location -Path $env:PuppetModuleRoot -ErrorAction Stop
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