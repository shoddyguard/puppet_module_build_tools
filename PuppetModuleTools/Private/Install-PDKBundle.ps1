# Needs to be a nested cmdlet cos of the 2>&1 issue :(
function Install-PDKBundle
{
    [CmdletBinding()]
    param 
    (
        # Expected exit codes
        [Parameter(mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [array]
        $ExpectedExitCodes = @(0),

        # Whether or not to disable PDK's output.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 3)]
        [bool]
        $SurpressPDKOutput = $true
    )
    $Command = 'pdk bundle install'
    if ($SurpressPDKOutput -eq $true)
    {
        $Command = $Command + ' 2>&1'
    }
    $PDK_Output = Invoke-Expression $Command
    if ($LASTEXITCODE -notin $ExpectedExitCodes)
    {
        throw "Bundle install failed, unhandled exit code. Exit code: $LASTEXITCODE"
    }
}