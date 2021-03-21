# Needs to be a nested cmdlet cos of the 2>&1 issue :(
function Install-PDKBundle
{
    [CmdletBinding()]
    param 
    (
        # Expected exit codes
        [Parameter(mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [array]
        $ExpectedExitCodes = @(0)
    )
    
    $PDK_Output = Invoke-Expression 'pdk bundle install 2>&1'
    if ($LASTEXITCODE -notin $ExpectedExitCodes)
    {
        throw "Bundle install failed, unhandled exit code. Exit code: $LASTEXITCODE"
    }
}