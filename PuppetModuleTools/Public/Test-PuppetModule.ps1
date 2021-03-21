<#
.SYNOPSIS
    Performs various tests against a give Puppet module
.DESCRIPTION
    Performs various tests against a give Puppet module
.EXAMPLE
    PS C:\> Test-PuppetModule -ModulePath c:\myModule
    Will test the module at c:\myModule
.INPUTS
    Module path: the path to the module to test
    TestAcceptance: Whether or not to perform an acceptance test using Puppet Litmus
    Provisioners: When testing acceptance this is the provisioner(s) to use
    SurpressPDKOutput: Whether or not to disable PDK's output. Useful to disable when you're interested in seeing the full output.
.NOTES
    There appears to be a bit of a bug when specifying 2>&1 in PoSh core 7.1 :(
    https://stackoverflow.com/questions/66726049/how-can-i-redirect-stdout-and-stderr-without-polluting-powershell-error-output/
    https://github.com/PowerShell/PowerShell/issues/3996

    Essentially PoSh treats anything written to stderr as an error but many programs don't want to put everything on stdout and so will write non-errors to stderr (eg info etc) 
    PDK is one of these programs meaning the try/catch blocks get sad and will terminate the first time pdk writes to stderr.
    Seeing as we handle throwing exceptions in all our cmdlets we should be safe to use -ErrorAction SilentlyContinue on all out try/catch blocks below.
    We could also look into writing custom exception classes and filtering the catch blocks to only grab those. (tried 2021-20-03 didn't work)
#>
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
    $DefaultParams = @{
        ErrorAction = 'SilentlyContinue'
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
    try
    {
        Install-PDKBundle @DefaultParams
    }
    catch
    {
        Pop-Location
        throw "$($_.Exception.Message)"
    }

    # Start by ensuring the module is up-to-date
    Write-Verbose "Checking module is up-to-date"
    try
    {
        Test-PuppetModuleUpdate @DefaultParams
    }
    catch
    {
        Pop-Location
        throw "Module update check has failed.`n$($_.Exception.Message)"
    }

    # Check conformity, if the above passes this should too so may be redundant, but keeping around for now.
    Write-Verbose "Checking if module needs to be converted"
    try
    {
        Test-PuppetModuleConversion @DefaultParams
    }
    catch
    {
        Pop-Location
        throw "Puppet module failed validation.`n$($_.Exception.Message)"
    }

    # Check the validation, again if the above has passed this is unlikely to be an issue but is good to check.
    Write-Verbose "Checking module validation"
    try
    {
        Test-PuppetValidation @DefaultParams
    }
    catch
    {
        Pop-Location
        throw "Validation check has failed.`n$($_.Exception.Message)"
    }

    # Perform unit tests
    Write-Verbose "Performing Puppet unit tests"
    try
    {
        Test-PuppetUnit @DefaultParams
    }
    catch
    {
        Pop-Location
        throw "Unit tests have failed.`n$($_.Exception.Message)"
    }

    # Finally perform acceptance tests if we've requested them
    if ($TestAcceptance -eq $true)
    {
        Write-Verbose "Performing acceptance test(s)"
        try
        {
            Test-PuppetAcceptance -Provisioners $Provisioners @DefaultParams
        }
        catch
        {
            throw "Acceptance tests have failed.`n$($_.Exception.Message)"
        }
        finally
        {
            Write-Verbose "Tearing down provisioner(s)"
            Remove-Provisioners @DefaultParams
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