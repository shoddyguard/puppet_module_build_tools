# Check that the relevant tools exist.
Write-Verbose "Checking prequisite tools are available on the path"
foreach ($bin in @('pdk', 'puppet', 'bolt', 'gem'))
{
    try
    {
        Get-Command $bin | Out-Null
    }
    catch
    {
        throw "Cannot find '$bin' on path."
    }
}

# Don't fail on accepatance tools, merely warn
Write-Verbose "Checking for the presence of acceptance testing tools"
try
{
    Get-Command 'vagrant' | Out-Null
}
catch
{
    Write-Warning "Vagrant is not available on path, this may be required for performing acceptance testing"
}
try
{
    Get-Command 'docker' | Out-Null
}
catch
{
    Write-Warning "Docker is not available on path, this may be required for performing acceptance testing"
}

# Forcefully import module to ensure it's always the latest
try
{
    Import-Module ./PuppetModuleTools/PuppetModuleTools.psm1 -Force
}
catch
{
    throw "Failed to import the PuppetModuleTools module.`n$($_.Exception.Message)"
}
Write-Host "Puppet tools successfully initialized!"