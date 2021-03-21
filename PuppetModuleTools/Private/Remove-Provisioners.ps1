# Need to nest this cos of the 2>&1 issue :(
function Remove-Provisioners
{
    [CmdletBinding()]
    param
    (
        $ValidExitCodes = @(0)
    )
    $PDK_Output = Invoke-Expression 'pdk bundle exec rake litmus:tear_down 2>&1'
    if ($LASTEXITCODE -notin $ValidExitCodes)
    {
        throw "Failed to remove provisioners, unhandled exit code. Exit code: $LASTEXITCODE"
    }
}