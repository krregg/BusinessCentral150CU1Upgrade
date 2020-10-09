function LoadModule160 {
    $NavAdminToolFile = "C:\Program Files\Microsoft Dynamics 365 Business Central\160\Service\NavAdminTool.ps1"
    Test-Path -Path $NavAdminToolFile -ErrorAction Stop -Verbose
    Import-Module -name $NavAdminToolFile -ErrorAction Stop -Verbose
}

function LoadModule170 {
    $NavAdminToolFile = "C:\Program Files\Microsoft Dynamics 365 Business Central\170\Service\NavAdminTool.ps1"
    Test-Path -Path $NavAdminToolFile -ErrorAction Stop -Verbose
    Import-Module -name $NavAdminToolFile -ErrorAction Stop -Verbose
}

#################################################################################
#                                                                               #
#               BC160 - Prepare for an Upgrade                                  #
#                                                                               #
#################################################################################

LoadModule160
$serverInstance = "bc160"
$licenceFilePath = "C:\temp\BC160\licence\licence.flf"
$dbName = "db"
$BaseApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "Base Application"
$SystemApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "System Application"

Import-NAVServerLicense -ServerInstance $serverInstance -LicenseFile $licenceFilePath -Verbose
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose

Get-NAVAppInfo -ServerInstance $serverInstance | ForEach-Object { 
    If (($_.Name -ne "System Application") -and ($_.Name -ne "Base Application") -and ($_.Name -ne "Application")) { 
        Uninstall-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose -Force} }

Get-NAVAppInfo -ServerInstance $serverInstance | ForEach-Object {
     If (($_.Name -ne "System Application") -and ($_.Name -ne "Base Application") -and ($_.Name -ne "Application")) { 
         Unpublish-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose } }

Uninstall-NAVApp -ServerInstance $serverInstance -Name "Application"
Uninstall-NAVApp -ServerInstance $serverInstance -Name "Base Application"
Uninstall-NAVApp -ServerInstance $serverInstance -Name "System Application"
Unpublish-NAVApp -ServerInstance $serverInstance -Name "Application" -Version $BaseApplication.Version -Verbose
Unpublish-NAVApp -ServerInstance $serverInstance -Name "Base Application" -Version $BaseApplication.Version -Verbose
Unpublish-NAVApp -ServerInstance $serverInstance -Name "System Application" -Version $SystemApplication.Version -Verbose

$intalledApps = Get-NAVAppInfo -ServerInstance $serverInstance
if ($intalledApps -eq 0) {
    Stop-NAVServerInstance -ServerInstance $serverInstance -Verbose }
else { 
    throw "$intalledApps are still installed."}

#################################################################################
#                                                                               #
#               BC170 - Upgrade                                                 #
#                                                                               #
#################################################################################

LoadModule170
$serverInstance = "bc170"
$licenceFilePath = "C:\temp\BC170\licence\licence.flf" 
$dbName = "db"
$newApplicationVersion = 17.0.16993.0

Invoke-NAVApplicationDatabaseConversion -DatabaseServer NL-SI-X09426A\mssql19 -DatabaseName $dbName -Verbose -Force
Set-NAVServerConfiguration -ServerInstance $serverInstance -KeyName DatabaseName -KeyValue $dbName -Verbose
Set-NavServerConfiguration -ServerInstance $serverInstance -KeyName "EnableTaskScheduler" -KeyValue false -Verbose
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose
Import-NAVServerLicense -ServerInstance $serverInstance -LicenseFile $licenceFilePath -Verbose
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose 

$systemPath = "C:\Program Files (x86)\Microsoft Dynamics 365 Business Central\170\AL Development Environment\System.app"
$baseAppPath = "C:\data\installs\BC17.0\bc\Applications\BaseApp\Source\Microsoft_Base Application.app"
$systemAppPath = "C:\data\installs\BC17.0\bc\Applications\system application\source\Microsoft_System Application.app" 
$applicationAppPath = "C:\data\installs\BC17.0\bc\Applications\Application\Source\Microsoft_Application.app"

if !(Test-Path -Path $systemPath) {
    throw "Path $systemPath is invalid."
}
if !(Test-Path -Path $systemAppPath) {
    throw "Path $systemPath is invalid."
}
if !(Test-Path -Path $baseAppPath) {
    throw "Path $systemPath is invalid."
}
if !(Test-Path -Path $applicationAppPath) {
    throw "Path $systemPath is invalid."
}

# Upgrade
Publish-NAVApp -ServerInstance $serverInstance -Path "$systemPath" -PackageType SymbolsOnly -Verbose 
Publish-NAVApp -ServerInstance $serverInstance -Path "$systemAppPath" -Verbose 
Publish-NAVApp -ServerInstance $serverInstance -Path "$baseAppPath" -Verbose
Publish-NAVApp -ServerInstance $serverInstance -Path "$applicationAppPath" -Verbose

Sync-NAVTenant -ServerInstance $serverInstance -Mode Sync -Force

$SystemApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "System Application"
$BaseApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "Base Application"
$Application = Get-NAVAppInfo -ServerInstance $serverInstance -Name "Application"

Sync-NAVApp -ServerInstance $serverInstance -Name "System Application" -Version $SystemApplication.Version -Verbose
Sync-NAVApp -ServerInstance $serverInstance -Name "Base Application" -Version $BaseApplication.Version -Verbose
Sync-NAVApp -ServerInstance $serverInstance -Name "Application" -Version $appApplication.Version -Verbose 

Start-NAVAppDataUpgrade -ServerInstance $serverInstance -Name "System Application" -Version $SystemApplication.Version -Force -Verbose
Start-NAVAppDataUpgrade -ServerInstance $serverInstance -Name "Base Application" -Version $BaseApplication.Version -Force -Verbose 
Start-NAVAppDataUpgrade -ServerInstance $serverInstance -Name "Application" -Version $Application.Version -Force -Verbose 

# Post Upgrade
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose
Set-NAVApplication -ServerInstance $serverInstance -ApplicationVersion $newApplicationVersion -Force -Verbose
Sync-NAVTenant -ServerInstance $serverInstance -Mode Sync -Force -Verbose
Start-NAVDataUpgrade -ServerInstance $serverInstance -Verbose -Force -SkipCompanyInitialization
Get-NAVDataUpgrade -ServerInstance $serverInstance -Progress

Set-NavServerConfiguration -ServerInstance $serverInstance -KeyName "EnableTaskScheduler" -KeyValue true -Verbose -Force
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose

$newApplicationDate = Get-NavApplication -ServerInstance $serverInstance
if ($newApplicationDate.ApplicationVersion -ne $newApplicationVersion) {
    $wrongVersion = $newApplicationDate.ApplicationVersion
    throw "Something went wrong with the upgrade process, new application version should be $newApplicationDate [current: $wrongVersion]"
}
else {
    Write-Host "Upgrade process finished."
}
