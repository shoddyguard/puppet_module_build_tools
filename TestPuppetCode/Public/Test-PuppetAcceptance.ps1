function Test-PuppetAcceptance
{
    [CmdletBinding()]
    param
    (
        # The provisioner(s) to use
        [Parameter(Mandatory = $false)]
        [array]
        $Provisioners = @('default'),

        # The path to the Puppet module to test against
        [Parameter(Mandatory = $false)]
        [string]
        $ModulePath = $env:PuppetModuleRoot
    )
    try
    {
        Push-Location -Path $ModulePath -ErrorAction Stop
    }
    catch
    {
        throw "$($_.Exception.Message)"
    }
    foreach ($Provisioner in $Provisioners)
    {
        $ProvisionerResult = ''
        try
        {
            $ProvisionerResult = Invoke-Expression "pdk bundle exec rake `"litmus:provision_list[$Provisioner]`""
        }
        catch
        {
            Pop-Location
            throw "Provisioner: $Provisioner has failed."
        }
        if ($LASTEXITCODE -ne 0)
        {
            Pop-Location
            throw "Provisoner returned a non-zero exit code."
        }
        if ($Provisioner -eq 'vagrant')
        {
            # If we're running vagrant then we'll need to get '/opt/puppet' onto roots path.
            $SetPuppetPathResult = ''
            try
            {
                $SetPuppetPathResult = Invoke-Expression "pdk bundle exec bolt task run provision::fix_secure_path --modulepath spec/fixtures/modules -i inventory.yaml -t ssh_nodes"
            }
            catch
            {
                Pop-Location
                throw "Failed to set secure path."
            }
            if ($LASTEXITCODE -ne 0)
            {
                Pop-Location
                throw "Failed to set secure path, non-zero exit code. Exit code: $LASTEXITCODE"
            }
        }
    }
    # Install Puppet agent on all running provisioners
    try
    {
        $AgentResult = Invoke-Expression 'pdk bundle exec rake litmus:install_agent'
    }
    catch
    {
        Pop-Location
        throw "Failed to install Puppet Agent."
    }
    if ($LASTEXITCODE -ne 0)
    {
        Pop-Location
        throw "Puppet agent install returned a non-zero exit code. Exit code: $LASTEXITCODE"
    }
    # Install the Puppet module
    try
    {
        $ModuleResult = Invoke-Expression 'pdk bundle exec rake litmus:install_module'
    }
    catch
    {
        Pop-Location
        throw "Failed to install Puppet module."
    }
    if ($LASTEXITCODE -ne 0)
    {
        Pop-Location
        throw "Module install returned a non-zero exit code. Exit code: $LASTEXITCODE"
    }

    # Perform the acceptance test(s)
    $TestResult = Invoke-Expression "pdk bundle exec rake litmus:acceptance:parallel"
    Pop-Location
    if ($LASTEXITCODE -ne 0)
    {
        throw "Acceptance tests have failed. Exit code: $LASTEXITCODE."
    }
    if ((-not($TestResult -match '0 failure')) -or ($TestResult -match 'error occurred'))
    {
        throw "Acceptance tests contain 1 or more failures/errors.`n$TestResult"
    }
    Write-Host "Acceptance tests passed succesfully" -ForegroundColor Green
}