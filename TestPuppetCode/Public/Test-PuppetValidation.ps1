function Test-PuppetValidation
{
    [CmdletBinding()]
    param(
        # The codes you expect PDK to return on a successful run
        [Parameter(Mandatory = $false)]
        [Array]
        $ValidExitCodes = @(0),

        # The path to the module to test against
        [Parameter(Mandatory = $false)]
        [string]
        $ModulePath
    )
    try
    {
        Push-Location -Path $ModulePath -ErrorAction Stop
    }
    catch
    {
        throw "$($_.Exception.Message)"
    }
    $Validation = Invoke-Expression 'pdk validate'
    Pop-Location
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        throw "Puppet module validation has failed. Exit code: $($LASTEXITCODE)"
    }
    Write-Host "Puppet module successfully passed validation" -ForegroundColor Green
}