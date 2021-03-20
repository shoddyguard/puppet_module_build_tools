function Test-PuppetModule
{
    [CmdletBinding()]
    param
    (
        # The path to the module to test
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string]
        $ModulePath,

        # Whether or not to perform an acceptance test using Puppet Litmus
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 1, ParameterSetName = 'Acceptance')]
        [bool]
        $TestAcceptance = $false,

        # When testing acceptance this is the provisioner(s) to use
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 2, ParameterSetName = 'Acceptance')]
        [array]
        $Provisioners = @('default')
    )

    # Check that the relevant tools exist. (should this maybe be in an init?)
    Write-Verbose "Checking prequisite tools are available on the path"
    foreach ($bin in @('pdk', 'puppet', 'bolt', 'gem'))
    {
        try
        {
            Get-Command $bin | Out-Null
        }
        catch
        {
            throw "Cannot find '$bin' on the path."
        }
    }

    # Navigate to the folder where we're going to test against
    Write-Verbose "Setting working directory to $ModulePath"
    try
    {
        Push-Location -Path $ModulePath
    }
    catch
    {
        throw "Cannot find $ModulePath"
    }

    # Install the gems - I wonder if gem update may be better here?
    Write-Verbose "Installing gems from gemfile"
    $BundleOutPut = Invoke-Expression 'pdk bundle install'
    if ($LASTEXITCODE -ne 0)
    {
        Pop-Location
        throw "Failed to install gems"
    }

    # Start by ensuring the module is up-to-date
    Write-Verbose "Checking module is up-to-date"
    try
    {
        Test-PuppetModuleUpdate
    }
    catch
    {
        Pop-Location
        throw "$($_.Exception.Message)"
    }

    # Check conformity, if the above passes this should too so may be redundant, but keeping around for now.
    Write-Verbose "Checking if module needs to be converted"
    try
    {
        Test-PuppetModuleConversion
    }
    catch
    {
        throw "$($_.Exception.Message)"
    }

    # Check the validation, again if the above has passed this is unlikely to be an issue but is good to check.
    Write-Verbose "Checking module validation"
    try
    {
        Test-PuppetValidation
    }
    catch
    {
        throw "$($_.Exception.Message)"
    }

    # Perform unit tests
    Write-Verbose "Performing Puppet unit tests"
    try
    {
        Test-PuppetUnit
    }
    catch
    {
        throw "$($_.Exception.Message)"
    }

    # Finally perform acceptance tests if we've requested them
    if ($TestAcceptance -eq $true)
    {
        Write-Verbose "Performing acceptance test(s)"
        try
        {
            Test-PuppetAcceptance
        }
        catch
        {
            throw "$($_.Exception.Message)"
        }
        finally
        {
            Write-Verbose "Tearing down provisioners"
            Start-Process 'pdk' -ArgumentList 'bundle exec rake litmus:tear_down' -Wait -NoNewWindow
            Write-Verbose "Popping location from stack"
            Pop-Location
            Write-Verbose "All checks completed successfully"
        }
    }
    else
    {
        Write-Verbose "Not performing acceptance testing, all other checks completed succesfully"
        Pop-Location
    }
}