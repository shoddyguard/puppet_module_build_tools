<#
.SYNOPSIS
    Helper tooling for performing tests on a Puppet module while developing it
.DESCRIPTION
    TBC
#>

[CmdletBinding()]
param()

# Stop on any errors
$ErrorActionPreference = 'Stop'
Write-Output "Checking prequisites"
try
{
    Get-Command 'pdk' | Out-Null
    Get-Command 'puppet' | Out-Null
    Get-Command 'bolt' | Out-Null
    Get-Command 'gem' | Out-Null
}
catch
{
    throw "One or more required tools are not on the path.`n$($_.Exception.Message)"
}
Write-Host "Prerequisite check ok" -ForegroundColor Green
Write-Output "Importing TestPuppetCode PowerShell module"
try
{
    Import-Module "$PSScriptRoot/TestPuppetCode/TestPuppetCode.psm1" -Force
}
catch
{
    throw "Failed to import TestPuppetCode module"
}
Write-Host "TestPuppetCode module imported" -ForegroundColor Green
Write-Output "Ensuring gems are present..."

$BundleOutPut = Invoke-Expression 'pdk bundle install'
if ($LASTEXITCODE -ne 0)
{
    throw "Failed to install gems."
}
Write-Host "Gems installed succesfully" -ForegroundColor Green
# Start by ensuring our module is up-to-date
Write-Output "Checking module is up-to-date..."
try
{
    Test-PuppetModuleConformity -CommandToExecute 'pdk update --noop'
}
catch
{
    throw "$($_.Exception.Message)"
}

# Check conformity, if the above passes this should too so may be redundant, but keeping around for now.
Write-Output "Checking module conformity..."
try
{
    Test-PuppetModuleConformity
}
catch
{
    throw "$($_.Exception.Message)"
}

# Check the validation, again if the above has passed this is unlikely to be an issue but is good to check.
Write-Output "Checking module validation..."
try
{
    Test-PuppetValidation
}
catch
{
    throw "$($_.Exception.Message)"
}

# Perform unit tests
Write-Output "Performing Puppet unit tests..."
try
{
    Test-PuppetUnit
}
catch
{
    throw "$($_.Exception.Message)"
}

# Finally perform acceptance tests
Write-Output "Performing acceptance test(s)..."
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
    Write-Host "Tearing down provisioners"
    Start-Process 'pdk' -ArgumentList 'bundle exec rake litmus:tear_down' -Wait -NoNewWindow
}
Write-Host "All checks have passed, module should be good to go!" -ForegroundColor Green