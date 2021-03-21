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
        $ProvisionCommand = "pdk bundle exec rake `"litmus:provision_list[$Provisioner]`" 2>&1"
        Write-Verbose "Setting up provisioner: $Provisioner"
        try
        {
            $ProvisionerResult = Invoke-Expression $ProvisionCommand
        }
        catch
        {
            $ProvisionerResult
            throw "Provisioner: $Provisioner has failed."
        }
        if ($LASTEXITCODE -ne 0)
        {
            $ProvisionerResult
            throw "Provisoner returned a non-zero exit code. Exit code: $LASTEXITCODE"
        }
        if ($Provisioner -eq 'vagrant')
        {
            Write-Verbose "Setting Puppet path"
            # If we're running vagrant then we'll need to get '/opt/puppet' onto roots path.
            $SetPuppetPathResult = ''
            $SetPuppetCommand = 'pdk bundle exec bolt task run provision::fix_secure_path --modulepath spec/fixtures/modules -i inventory.yaml -t ssh_nodes 2>&1'
            try
            {
                $SetPuppetPathResult = Invoke-Expression $SetPuppetCommand
            }
            catch
            {
                $SetPuppetPathResult
                throw "Failed to set secure path."
            }
            if ($LASTEXITCODE -ne 0)
            {
                $SetPuppetPathResult
                throw "Failed to set secure path, non-zero exit code. Exit code: $LASTEXITCODE"
            }
        }
    }
    # Install Puppet agent on all running provisioners
    Write-Verbose "Installing Puppet Agent"
    $AgentCommand = 'pdk bundle exec rake litmus:install_agent 2>&1'
    try
    {
        $AgentResult = Invoke-Expression $AgentCommand
    }
    catch
    {
        $AgentResult
        throw "Failed to install Puppet Agent."
    }
    if ($LASTEXITCODE -ne 0)
    {
        $AgentResult
        throw "Puppet agent install returned a non-zero exit code. Exit code: $LASTEXITCODE"
    }
    # Install the Puppet module
    Write-Verbose "Installing Puppet module"
    $ModuleCommand = 'pdk bundle exec rake litmus:install_module 2>&1'
    try
    {
        $ModuleResult = Invoke-Expression $ModuleCommand
    }
    catch
    {
        $ModuleResult
        throw "Failed to install Puppet module."
    }
    if ($LASTEXITCODE -ne 0)
    {
        $ModuleResult
        throw "Module install returned a non-zero exit code. Exit code: $LASTEXITCODE"
    }

    # Perform the acceptance test(s)
    Write-Verbose "Performing litmus test(s)"
    $TestCommand = 'pdk bundle exec rake litmus:acceptance:parallel 2>&1'
    $TestResult = Invoke-Expression $TestCommand
    if ($LASTEXITCODE -ne 0)
    {
        $TestResult
        throw "Acceptance tests have failed. Exit code: $LASTEXITCODE."
    }
    if ((-not($TestResult -match '0 failure')) -or ($TestResult -match 'error occurred'))
    {
        $TestResult
        throw "Acceptance tests contain 1 or more failures/errors.`n$TestResult"
    }
    Write-Verbose "Acceptance tests passed succesfully"
}