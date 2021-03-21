<#
    Build used in GitHub actions for testing Puppet Modules before release.
    Does not perform acceptance testing as we take care of that in a separate GitHub action.
 #>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [string]
    $ModulePath
)
if ($env:CI)
{
    $VerbosePreference = "continue"
}
try
{
    $PuppetModuleToolsPath = (Get-Item $PSScriptRoot -Force).Parent.FullName
    Import-Module "$PuppetModuleToolsPath/PuppetModuleTools/PuppetModuleTools.psm1" -Force -ErrorAction Stop
}
catch
{
    throw "Failed to Import PuppetModuleTools PoSh module"
}

try
{
    Test-PuppetModule -ModulePath $ModulePath -TestAcceptance:$true -Provisioners @('GitHub')
}
catch
{
    throw "$($_.Exception.Message)"
}