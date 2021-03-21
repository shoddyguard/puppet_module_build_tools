# Need to nest this cos of the 2>&1 issue :(
function Remove-Provisioners
{
    [CmdletBinding()]
    param
    (
        $ValidExitCodes = @(0)
    )
    $Command = 'pdk bundle exec rake litmus:tear_down 2>&1'
    $PDK_Output = Invoke-Expression $Command
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        $PDK_Output
        throw "Failed to remove provisioners, unhandled exit code. Exit code: $LASTEXITCODE"
    }
}