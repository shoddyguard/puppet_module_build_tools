# Need to nest this cos of the 2>&1 issue :(
function Remove-Provisioners
{
    [CmdletBinding()]
    param
    (
        $ValidExitCodes = @(0),

        # Whether or not to disable PDK's output.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 3)]
        [bool]
        $SurpressPDKOutput = $true
    )
    $Command = 'pdk bundle exec rake litmus:tear_down'
    if ($SurpressPDKOutput -eq $true)
    {
        $Command = $Command + ' 2>&1'
    }
    $PDK_Output = Invoke-Expression $Command
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        throw "Failed to remove provisioners, unhandled exit code. Exit code: $LASTEXITCODE"
    }
}