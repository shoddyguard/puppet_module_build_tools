<#
.SYNOPSIS
    Performs acceptance tests against a Puppet module
.DESCRIPTION
    Performs Puppet Litmus acceptance testing against a Puppet module
.EXAMPLE
    PS C:\myModule> Test-PuppetAcceptance -Provisioners vagrant
    Will perform acceptance testing using Vagrant on the module located at c:\myModule
.INPUTS
    Provisioners: the provisioner(s) to use for testing (the ones defined in provisioners.yaml)
#>
function Test-PuppetAcceptance
{
    [CmdletBinding()]
    param
    (
        # The provisioner(s) to use
        [Parameter(Mandatory = $false)]
        [array]
        $Provisioners = @('default')
    )
    foreach ($Provisioner in $Provisioners)
    {
        $ProvisionerResult = ''
        try
        {
            $ProvisionerResult = Invoke-Expression "pdk bundle exec rake `"litmus:provision_list[$Provisioner]`" 2>&1"
        }
        catch
        {
            throw "Provisioner: $Provisioner has failed."
        }
        if ($LASTEXITCODE -ne 0)
        {
            throw "Provisoner returned a non-zero exit code. Exit code: $LASTEXITCODE"
        }
        if ($Provisioner -eq 'vagrant')
        {
            # If we're running vagrant then we'll need to get '/opt/puppet' onto roots path.
            $SetPuppetPathResult = ''
            try
            {
                $SetPuppetPathResult = Invoke-Expression "pdk bundle exec bolt task run provision::fix_secure_path --modulepath spec/fixtures/modules -i inventory.yaml -t ssh_nodes 2>&1'"
            }
            catch
            {
                throw "Failed to set secure path."
            }
            if ($LASTEXITCODE -ne 0)
            {
                throw "Failed to set secure path, non-zero exit code. Exit code: $LASTEXITCODE"
            }
        }
    }
    # Install Puppet agent on all running provisioners
    try
    {
        $AgentResult = Invoke-Expression 'pdk bundle exec rake litmus:install_agent 2>&1'
    }
    catch
    {
        throw "Failed to install Puppet Agent."
    }
    if ($LASTEXITCODE -ne 0)
    {
        throw "Puppet agent install returned a non-zero exit code. Exit code: $LASTEXITCODE"
    }
    # Install the Puppet module
    try
    {
        $ModuleResult = Invoke-Expression 'pdk bundle exec rake litmus:install_module 2>&1'
    }
    catch
    {
        throw "Failed to install Puppet module."
    }
    if ($LASTEXITCODE -ne 0)
    {
        throw "Module install returned a non-zero exit code. Exit code: $LASTEXITCODE"
    }

    # Perform the acceptance test(s)
    $TestResult = Invoke-Expression "pdk bundle exec rake litmus:acceptance:parallel 2>&1"
    if ($LASTEXITCODE -ne 0)
    {
        throw "Acceptance tests have failed. Exit code: $LASTEXITCODE."
    }
    if ((-not($TestResult -match '0 failure')) -or ($TestResult -match 'error occurred'))
    {
        throw "Acceptance tests contain 1 or more failures/errors.`n$TestResult"
    }
    Write-Verbose "Acceptance tests passed succesfully"
}