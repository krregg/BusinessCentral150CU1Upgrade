function HandleBC150() {
Write-Host "###############################################"
Write-Host "#                                             #"
Write-Host "#                                             #"
Write-Host "#           Upgrade to BC150 CU1              #"
Write-Host "#                                             #"
Write-Host "#                                             #"
Write-Host "###############################################"

$databaseServer = "server\instance"
$databaseName = "dbname"
$instance = "bc150"
$prodLicence = "C:\temp\licence.flf"

$systemSymbols = "C:\temp\app\System.app"
$systemApp = "C:\temp\app\Microsoft_System Application.app"
$baseApp = "C:\temp\app\Microsoft_Base Application_15.1.37881.38071.app"
$customApp = "C:\temp\app\Custom_App_1.0.0.0.app"

Import-Module -name "C:\Program Files\Microsoft Dynamics 365 Business Central\150\Service\NavAdminTool.ps1"

Write-Host "Convert database for BC150"
Invoke-NAVApplicationDatabaseConversion -DatabaseServer $databaseServer -DatabaseName $databaseName #-Force

Write-Host "Set database connection"
Set-NAVServerConfiguration -ServerInstance $instance -KeyName DatabaseName -KeyValue $databaseName

Write-Host "Set dependencies for destination apps"
Set-NAVServerConfiguration -ServerInstance $instance -KeyName "DestinationAppsForMigration" -KeyValue '[{"appId":"63ca2fa4-4f03-4f2b-a480-172fef340d3f", "name":"System Application", "publisher": "Microsoft"},{"appId":"437dbf0e-84ff-417a-965d-ed2bb9650972", "name":"Base Application", "publisher": "Microsoft"}]'

Write-Host "Disable task scheduler"
Set-NavServerConfiguration -ServerInstance $instance -KeyName "EnableTaskScheduler" -KeyValue false
     
Write-Host "Restart service and set application version 15.1.38071.0"
Restart-NAVServerInstance -ServerInstance $instance
Sleep -Seconds 10

Set-NAVApplication -ServerInstance $instance -ApplicationVersion 15.1.38071.0 -Force

Write-Host "Publish symbols, system and base app (takes a while...)"
Publish-NAVApp -ServerInstance  $instance -Path $systemSymbols -PackageType SymbolsOnly
Publish-NAVApp -ServerInstance $instance -Path $systemApp
Publish-NAVApp -ServerInstance $instance -Path $baseApp -SkipVerification
    
Restart-NAVServerInstance -ServerInstance $instance #skip
Sleep -Seconds 10

Write-Host "Sync tenant in Sync mode"
Sync-NAVTenant -ServerInstance $instance -Mode Sync #-Force

Write-Host "Sync System and Base App"
Sync-NAVApp -ServerInstance $instance -Name "System Application" -Version 15.1.37881.38071
Sync-NAVApp -ServerInstance $instance -Name "Base Application" -Version 15.1.37881.38071 
    
Write-Host "Start Nav Data Upgrade"
Start-NAVDataUpgrade -ServerInstance $instance -Tenant default -FunctionExecutionMode Serial #-SkipAppVersionCheck


Write-Host "Start Nav Data Upgrade in progress. (Get-NAVDataUpgrade -Progress -ServerInstance $instance) Check progress and continues manualy..."
}

function InstallCustomApp() {
Restart-NAVServerInstance -ServerInstance $instance
Publish-NAVApp -ServerInstance $instance -Path $customApp -SkipVerification
Sync-NAVApp -ServerInstance $instance -Name CustomAppName -Version 1.0.0.0
#Start-NAVAppDataUpgrade -ServerInstance $instance -Name CustomAppName -Version 1.0.0.0 # optional if using versions
Install-NAVApp -ServerInstance $instance -Name CustomAppName -Version 1.0.0.0
}

function PostDeployTasks() {
Set-NavServerConfiguration -ServerInstance $instance -KeyName "EnableTaskScheduler" -KeyValue true
Import-NAVServerLicense -ServerInstance $instance -LicenseFile $prodLicence -Database NavDatabase

Restart-NAVServerInstance -ServerInstance $instance
}

HandleBC150

### manual ###
Get-NAVDataUpgrade -Progress -ServerInstance $instance

### wait until Start-NAVDataUpgrade is completed ###
### manual ###

InstallCustomApp
PostDeployTasks
