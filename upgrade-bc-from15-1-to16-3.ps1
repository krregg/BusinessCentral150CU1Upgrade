function LoadModule150 {
    $NavAdminToolFile = "C:\Program Files\Microsoft Dynamics 365 Business Central\150\Service\NavAdminTool.ps1"
    Test-Path -Path $NavAdminToolFile -ErrorAction Stop -Verbose
    Import-Module -name $NavAdminToolFile -ErrorAction Stop -Verbose
}

function LoadModule160 {
    $NavAdminToolFile = "C:\Program Files\Microsoft Dynamics 365 Business Central\160\Service\NavAdminTool.ps1"
    Test-Path -Path $NavAdminToolFile -ErrorAction Stop -Verbose
    Import-Module -name $NavAdminToolFile -ErrorAction Stop -Verbose
}

# BC15.1
# download https://www.microsoft.com/en-us/download/details.aspx?id=100600
LoadModule150
$serverInstance = "bc150"
$licenceFilePath = "C:\temp\BC150\licence\licence.flf"
$dbName = "db"
$BaseApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "Base Application"
$SystemApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "System Application"

Import-NAVServerLicense -ServerInstance $serverInstance -LicenseFile $licenceFilePath -Verbose
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose
Get-NAVAppInfo -ServerInstance $serverInstance | ForEach-Object { If (($_.Name -ne "System Application") -and ($_.Name -ne "Base Application")) { Uninstall-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose -Force} }
Get-NAVAppInfo -ServerInstance $serverInstance | ForEach-Object { If (($_.Name -ne "System Application") -and ($_.Name -ne "Base Application")) { Unpublish-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose } }
Get-NAVAppInfo -ServerInstance $serverInstance | ForEach-Object { Uninstall-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose -Force }
Unpublish-NAVApp -ServerInstance $serverInstance -Name "Base Application" -Version $BaseApplication.Version -Verbose
Unpublish-NAVApp -ServerInstance $serverInstance -Name "System Application" -Version $SystemApplication.Version -Verbose
Get-NAVAppInfo -ServerInstance $serverInstance -SymbolsOnly | ForEach-Object { Unpublish-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose}
Stop-NAVServerInstance -ServerInstance $serverInstance -Verbose

###################################################################

# Start BC16.0
# download https://mbs.microsoft.com/partnersource/global/support/support-news/msdbcentralonprem20wave1
LoadModule160
$serverInstance = "bc160"
$licenceFilePath = "C:\temp\BC160\licence\licence.flf" 
$dbName = "db"

Invoke-NAVApplicationDatabaseConversion -DatabaseServer server\mssql19 -DatabaseName $dbName -Verbose -Force
Set-NAVServerConfiguration -ServerInstance $serverInstance -KeyName DatabaseName -KeyValue $dbName -Verbose
Set-NavServerConfiguration -ServerInstance $serverInstance -KeyName "EnableTaskScheduler" -KeyValue false -Verbose
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose
Import-NAVServerLicense -ServerInstance $serverInstance -LicenseFile $licenceFilePath -Verbose
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose 

$systemPath = "C:\Program Files (x86)\Microsoft Dynamics 365 Business Central\160\AL Development Environment\System.app"
$baseAppPath = "C:\data\installs\BC16.0\bc\Applications\BaseApp\Source\Microsoft_Base Application.app"
$systemAppPath = "C:\data\installs\BC16.0\bc\Applications\system application\source\Microsoft_System Application.app" 
$applicationAppPath = "C:\data\installs\BC16.0\bc\Applications\Application\Source\Microsoft_Application.app"

Test-Path -Path $systemPath
Test-Path -Path $systemAppPath
Test-Path -Path $baseAppPath
Test-Path -Path $applicationAppPath

Publish-NAVApp -ServerInstance $serverInstance -Path "$systemPath" -PackageType SymbolsOnly -Verbose 
Publish-NAVApp -ServerInstance $serverInstance -Path "$systemAppPath" -Verbose 
Publish-NAVApp -ServerInstance $serverInstance -Path "$baseAppPath" -Verbose
$SystemApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "System Application"
$BaseApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "Base Application"
Publish-NAVApp -ServerInstance $serverInstance -Path "$applicationAppPath" -Verbose
Sync-NAVTenant -ServerInstance $serverInstance -Mode Sync -Force
Sync-NAVApp -ServerInstance $serverInstance -Name "System Application" -Version $SystemApplication.Version -Verbose
Sync-NAVApp -ServerInstance $serverInstance -Name "Base Application" -Version $BaseApplication.Version -Verbose
Sync-NAVApp -ServerInstance $serverInstance -Name "Application" -Version $appApplication.Version -Verbose 
Start-NAVAppDataUpgrade -ServerInstance $serverInstance -Name "System Application" -Version $SystemApplication.Version -Force -Verbose
Start-NAVAppDataUpgrade -ServerInstance $serverInstance -Name "Base Application" -Version $BaseApplication.Version -Force -Verbose 
Install-NAVApp -ServerInstance $serverInstance -Name "Application" -Verbose


# Post Upgrade Steps
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose
Set-NAVApplication -ServerInstance $serverInstance -ApplicationVersion 16.0.11240.12076 -Force -Verbose
Sync-NAVTenant -ServerInstance $serverInstance -Mode Sync -Force -Verbose
Start-NAVDataUpgrade -ServerInstance $serverInstance -Verbose -Force -SkipCompanyInitialization
Get-NAVDataUpgrade -ServerInstance $serverInstance -Progress

Set-NavServerConfiguration -ServerInstance $serverInstance -KeyName "EnableTaskScheduler" -KeyValue true -Verbose -Force
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose

# uninstall

Get-NAVAppInfo -ServerInstance $serverInstance | ForEach-Object { If (($_.Name -ne "System Application") -and ($_.Name -ne "Base Application")) { Uninstall-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose -Force} }
Get-NAVAppInfo -ServerInstance $serverInstance | ForEach-Object { If (($_.Name -ne "System Application") -and ($_.Name -ne "Base Application")) { Unpublish-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose } }
Get-NAVAppInfo -ServerInstance $serverInstance | ForEach-Object { Uninstall-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose -Force }
Unpublish-NAVApp -ServerInstance $serverInstance -Name "Base Application" -Version $BaseApplication.Version -Verbose
Unpublish-NAVApp -ServerInstance $serverInstance -Name "System Application" -Version $SystemApplication.Version -Verbose
Get-NAVAppInfo -ServerInstance $serverInstance -SymbolsOnly | ForEach-Object { Unpublish-NAVApp -ServerInstance $serverInstance -Name $_.Name -Version $_.Version -Verbose}
Stop-NAVServerInstance -ServerInstance $serverInstance -Verbose


###################################################################

# Start BC16.3
# download https://www.microsoft.com/en-us/download/details.aspx?id=101461
LoadModule160
$serverInstance = "bc160"
$licenceFilePath = "C:\temp\BC160\licence\licence.flf" 
$dbName = "db"

Invoke-NAVApplicationDatabaseConversion -DatabaseServer NL-SI-X09426A\mssql19 -DatabaseName $dbName -Verbose -Force
Set-NAVServerConfiguration -ServerInstance $serverInstance -KeyName DatabaseName -KeyValue $dbName -Verbose
Set-NavServerConfiguration -ServerInstance $serverInstance -KeyName "EnableTaskScheduler" -KeyValue false -Verbose
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose

$systemPath = "C:\Program Files (x86)\Microsoft Dynamics 365 Business Central\160\AL Development Environment\System.app"
$baseAppPath = "C:\temp\BC160\Maia365\apps\baseApp\Microsoft_Base Application_16.3.14085.14238.app"
$systemAppPath = "C:\data\installs\BC16.3\Applications\system application\source\Microsoft_System Application.app" 
$applicationAppPath = "C:\data\installs\BC16.3\Applications\Application\Source\Microsoft_Application.app"

Test-Path -Path $systemPath 
Test-Path -Path $systemAppPath
Test-Path -Path $baseAppPath
Test-Path -Path $applicationAppPath

Publish-NAVApp -ServerInstance $serverInstance -Path "$systemPath" -PackageType SymbolsOnly -Verbose 
Publish-NAVApp -ServerInstance $serverInstance -Path "$systemAppPath" -Verbose  
Publish-NAVApp -ServerInstance $serverInstance -Path "$baseAppPath" -Verbose -SkipVerification
Publish-NAVApp -ServerInstance $serverInstance -Path "$applicationAppPath" -Verbose
$SystemApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "System Application"
$BaseApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "Base Application"
$appApplication = Get-NAVAppInfo -ServerInstance $serverInstance -Name "Application"
Sync-NAVTenant -ServerInstance $serverInstance -Mode Sync -Force
Sync-NAVApp -ServerInstance $serverInstance -Name "System Application" -Version $SystemApplication.Version -Verbose
Sync-NAVApp -ServerInstance $serverInstance -Name "Base Application" -Version $BaseApplication.Version -Verbose
Sync-NAVApp -ServerInstance $serverInstance -Name "Application" -Verbose 
Start-NAVAppDataUpgrade -ServerInstance $serverInstance -Name "System Application" -Version $SystemApplication.Version -Force -Verbose
Start-NAVAppDataUpgrade -ServerInstance $serverInstance -Name "Base Application" -Version $BaseApplication.Version -Force -Verbose 
Start-NAVAppDataUpgrade -ServerInstance $serverInstance -Name "Application" -Version $appApplication.Version -Force -Verbose 

Set-NAVApplication -ServerInstance $serverInstance -ApplicationVersion 16.3.14085.14238 -Force -Verbose
Sync-NAVTenant -ServerInstance $serverInstance -Mode Sync -Force -Verbose
Start-NAVDataUpgrade -ServerInstance $serverInstance -Verbose -Force -SkipCompanyInitialization
Get-NAVDataUpgrade -ServerInstance $serverInstance -Progress
Set-NavServerConfiguration -ServerInstance $serverInstance -KeyName "EnableTaskScheduler" -KeyValue true -Verbose
Restart-NAVServerInstance -ServerInstance $serverInstance -Verbose

Publish-NAVApp -ServerInstance bc160 -Path "C:\temp\BC160\Maia365\apps\other\Microsoft_Any.app" -SkipVerification 
Publish-NAVApp -ServerInstance bc160 -Path "C:\temp\BC160\Maia365\apps\other\Microsoft_Library Assert.app" -SkipVerification 
Publish-NAVApp -ServerInstance bc160 -Path "C:\temp\BC160\Maia365\apps\other\Microsoft_Test Runner.app" -SkipVerification 

Sync-NAVApp bc160 -Name "Any"
Sync-NAVApp bc160 -Name "Library Assert"
Sync-NAVApp bc160 -Name "Test Runner"

Install-NAVApp bc160 -Name "Any"
Install-NAVApp bc160 -Name "Library Assert"
Install-NAVApp bc160 -Name "Test Runner"
