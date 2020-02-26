
function HandleBC140() {

Write-Host "###############################################"
Write-Host "#                                             #"
Write-Host "#                                             #"
Write-Host "#         Prepare BC140 for upgrade           #"
Write-Host "#                                             #"
Write-Host "#                                             #"
Write-Host "###############################################"

$instance = "bc140"
$devLicence = "C:\temp\licence.flf"
Import-Module -name "C:\Program Files\Microsoft Dynamics 365 Business Central\140\Service\NavAdminTool.ps1"

Write-Host "Disable Task Scheduler"
Set-NavServerConfiguration -ServerInstance $instance -KeyName "EnableTaskScheduler" -KeyValue false

Write-Host "Import dev licence"
Import-NAVServerLicense -ServerInstance $instance -LicenseFile $devLicence -Database NavDatabase

Write-Host "Restart service and wait 10 seconds"
Restart-NAVServerInstance -ServerInstance $instance
Sleep -Seconds 10

Write-Host "Uninstall apps"
try {
    Get-NAVAppInfo -ServerInstance $instance | % { Unpublish-NAVApp -ServerInstance $instance -Name $_.Name -Version $_.Version }
}
catch {
    Write-Host "$_.Exception.Message"
}

Write-Host "Unpublish apps"
try {
    Get-NAVAppInfo -ServerInstance $instance -SymbolsOnly | % { Unpublish-NAVApp -ServerInstance $instance -Name $_.Name -Version $_.Version }
}
catch {
    Write-Host "$_.Exception.Message"
}

Write-Host "Unpublish system symbols"
Get-NAVAppInfo -ServerInstance $instance -SymbolsOnly | % { Unpublish-NAVApp -ServerInstance $instance -Name $_.Name -Version $_.Version }

$apps = Get-NAVAppInfo -ServerInstance $instance
if ($apps) {
    Write-Host "Extensions still not removed completly."
    }
else {
    Write-Host "Extensions uninstalled completly, turning off NST"
    Stop-NAVServerInstance -ServerInstance $instance
    }
}
