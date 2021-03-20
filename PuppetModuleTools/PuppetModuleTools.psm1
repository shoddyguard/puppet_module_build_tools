[CmdletBinding()]
param()
# Get the folder wot contains everything.
$PublicCmdlets = @()
# Work out which SU check to perform

$ErrorActionPreference = 'Stop'

# Import our modules and export public functions
"$PSScriptRoot\Private\" |
  Resolve-Path |
    Get-ChildItem -Filter *.ps1 -Recurse |
      ForEach-Object {
        . $_.FullName
      }

"$PSScriptRoot\Public\" |
  Resolve-Path |
    Get-ChildItem -Filter *.ps1 -Recurse |
      ForEach-Object {
        . $_.FullName
        Export-ModuleMember -Function $_.BaseName
        $PublicCmdlets += Get-Help $_.BaseName
      }

# If PSCommandPath is blank it means that the module has been called directly, however if it's not then that means another PowerShell script has called this
# This is basically a nice way of limiting the stdout
if (!$MyInvocation.PSCommandPath)
{
  Write-Host "The following cmldets are now available for use:" -ForegroundColor White
  $PublicCmdlets | ForEach-Object { Write-Host "    $($_.Name) " -ForegroundColor Yellow -NoNewline; Write-Host "|  $($_.Synopsis)" -ForegroundColor White} 
}
