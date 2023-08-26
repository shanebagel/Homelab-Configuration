# Windows Server 2:

# 1. Set DNS to Server 1 on Internal Adapter
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses "192.168.1.100"

# 2. Set Static IP, and Gateway to Host Adapter IP
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 192.168.1.101 -PrefixLength "24" -DefaultGateway 192.168.1.1

# Set priority metric on "Ethernet 2" (Internal) Adapter 
Get-NetAdapter | Where-Object -FilterScript {$_.Name -Eq "Ethernet 2"} | Set-NetIPInterface -InterfaceMetric 0
Get-NetAdapter | Where-Object -FilterScript {$_.Name -Eq "Ethernet"} | Set-NetIPInterface -InterfaceMetric 10

# 3. Disable firewall
Set-NetFirewallProfile -Enabled False

# 4. Disable IPv6
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

# 5. Setting Hostname
Rename-Computer -NewName "ShaneServer2"
Restart-Computer

# 6. Setting Time Zone
Set-TimeZone -Name "Eastern Standard Time"

# 7. Install ADDS and Management tools
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

# 8. Join Server 2 to Domain
Install-ADDSDomainController -DomainName "ad.smhcomputers.com" -Credential (Get-Credential "ad\Admin")

# 9. Install PowerShell Version 7
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

# 10. Creating a list of modules
$Modules = @( 
"Az", 
"AzureAD", 
"MicrosoftTeams", 
"ExchangeOnlineManagement", 
"Microsoft.Online.SharePoint.PowerShell", 
"SharePointPnPPowerShellOnline", 
"Microsoft.Graph", 
"MSOnline" 
)

# 11. Installing Modules
Install-Module -Name $Modules -Force

# 12. Update PowerShell Help
Update-Help

# 13. Disable IE Enhanced Security 
function Disable-InternetExplorerESC {
      $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
      $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
      Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
      Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
      Rundll32 iesetup.dll, IEHardenLMSettings
      Rundll32 iesetup.dll, IEHardenUser
      Rundll32 iesetup.dll, IEHardenAdmin
      Write-Host "IE Enhanced Security Configuration (ESC) has been disabled."
 }
Disable-InternetExplorerEsc

# 14. Installing and Configuring Windows File Server
Install-WindowsFeature File-Services

# Configuring Network share on File Server for GPO deployment
Set-Location C:\
New-Item -Type Directory -Name ShaneShare
New-SmbShare -Path C:\ShaneShare -Name "ShaneShare"

# 15. Install Print and Document Services 
Install-WindowsFeature Print-Services

# Create Driver Directory
Set-Location "C:\"
New-Item -Type Directory -Name "Drivers"
Set-Location Drivers

# Disable Progress Preference 
$ProgressPreference= 'SilentlyContinue'

# Download Driver
$url = "https://ftp.hp.com/pub/softlib/software13/printers/UPD/upd-pcl6-x64-7.1.0.25570.exe"
$path = "C:\Drivers\Driver.exe"
Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing

# Install Driver 
Start-Process -Wait -FilePath ".\Driver.exe" -ArgumentList "/S /v/qn" -PassThru

# Get list of newly installed printer drivers
Get-PrinterDriver

# Test network connectivity to printer
Test-Connection -ComputerName 192.168.1.125

# Add TCP/IP printer port
Add-PrinterPort -Name "TCPPort:" -PrinterHostAddress "192.168.1.125"

# Add printer via TCP/IP
Add-Printer -Name "HP Printer" -DriverName "HP Universal Printing PCL 6" -PortName "TCPPort:"

# Validate printer was added
Get-Printer | Where-Object -Filter {$_.Name -eq "HP Printer"}

# Share printer to other devices on network
Set-Printer -Name "HP Printer" -Shared $True -ShareName "HP Printer"

# Validate printer share was added
Get-Printer | Where-Object -FilterScript {$_.ShareName -eq "HP Printer"}

# 16. Installation and Configuration of SQL Server PowerShell Module
Install-Module SQLServer 

# Installation of dbatools
Install-Module dbatools 

# Setting path for SQL Installation and downloading installer files
Set-Location C:\
New-Item -Type Directory -Name "SQL"
Set-Location C:\SQL
$ProgressPreference= 'SilentlyContinue'

$url = "https://aka.ms/ssmsfullsetup"
$path = "C:\SQL\﻿﻿SSMS-Setup-ENU.exe"
Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing

$url2 = "https://go.microsoft.com/fwlink/p/?linkid=2216019&clcid=0x409&culture=en-us&country=us"
$path2 = "C:\SQL\SQLServer.exe"
Invoke-WebRequest -Uri $url2 -OutFile $path2 -UseBasicParsing

# Installation of SQL Server Express and SSMS
Start-Process -Wait -FilePath ".\﻿﻿SSMS-Setup-ENU.exe" -ArgumentList "/S /v/qn" -PassThru
Start-Process -Wait -FilePath ".\SQLServer.exe" -ArgumentList "/S /v/qn" -PassThru

# Instance Name: SQLEXPRESS
# Connection String: Server=localhost\SQLEXPRESS;Database=master;Trusted_Connection=True;
# Server Instance: SHANESERVER2\SQLEXPRESS

# Set sa password
# Enable sa login
# Set SQL Server and Windows Authentication mode in SSMS under 'Security'

# Restart SQL Server Service
Restart-Service -Name 'MSSQL$SQLEXPRESS'

# Set your Connection String for your SQL Server Database
$DiskInfoSqlConnection = "Server=localhost\SQLEXPRESS;Database=master;Trusted_Connection=True;" 

# Create a new object representing the connection to your SQL Server
$Connection = New-Object System.Data.SqlClient.SqlConnection 

# Set the ConnectionString property to the databases Connection String
$Connection.ConnectionString = $DiskInfoSqlConnection 

# Open the connection by calling the open method
$Connection.Open() 

# Building a SQL Query - Can be any CRUD operation - Inserting SQL Code here
 
# Creating a table
$sql = @"       
CREATE TABLE ShaneExampleTable(
  age tinyint,
  gender char(1),
  first_name varchar(15),
  last_name varchar(15),
  car varchar(15),
  profession varchar(25),
  school char(3)
);
"@

# Creating an insert statement
$sql = @"
INSERT INTO ShaneExampleTable (age, gender, first_name, last_name, car, profession, school) 
VALUES (25, 'M', 'Shane', 'Hartley', 'Ford', 'Information Technology', 'FAU');
"@

# Create a new object representing the SQL Query
$Cmd = New-Object System.Data.SqlClient.SqlCommand 

# Set the Connection property of your command to be your Connection object created earlier
$Cmd.Connection = $Connection 

# Set the command text to be your SQL Query
$Cmd.CommandText = $sql 

# Execute the SQL Query by calling the Execute method
$Cmd.ExecuteNonQuery() | Out-Null

# Close the connection
$Connection.Close() 

# 17. WSUS Installation and Configuration - Local Windows Database
Install-WindowsFeature -Name UpdateServices, UpdateServices-Ui , UpdateServices-WidDB -IncludeManagementTools

# Set Database to WSUS Directory 
Set-Location "C:\Program Files\Update Services\Tools"
.\WsusUtil.exe PostInstall CONTENT_DIR=C:\WSUS

# Connect to WSUS Database
[void][reflection.assembly]::LoadWithPartialName(“Microsoft.UpdateServices.Administration”)
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer('shaneserver2',$False,8530)

# Add "Shane WSUS Production Computers" Group

# Configuring GPO to point computers at WSUS server
# Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Update\Configure Automatic Updates
# Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Update\Specify intranet Microsoft update service location

# Enable both policies - Set the WSUS Server that clients will use for updates via GPO
# Set the intranet update service for detecting updates: http://ShaneServer2.ad.smhcomputers.com:8530
# Set the intranet statistics server: http://ShaneServer2.ad.smhcomputers.com:8530

# Set Automatic Synchronization Schedule - First Synchronization: 12:00:00 am, Synchronizations per day: 1
# Set Automatic Approvals - New Rule: When an update is in a specific classification: Critical Updates

# Add Client Computers to WSUS Computer Group
Get-WsusComputer | Add-WsusComputer -TargetGroupName "Shane WSUS Production Computers"

# Configure Synchronization Source to be Microsoft Update
Set-WsusServerSynchronization -SyncFromMU

# Start WSUS and Windows Update Services
Get-Service -Name "WsusService" | Start-Service
Get-Service -Name "Wuauserv" | Start-Service

# Start Update Synchronization 
(Get-WsusServer).GetSubscription().StartSynchronization()

# Approve Critical Updates for Production Computers Manually
Get-WsusUpdate | Where-object {$_.Classification -like "Critical Updates"} | Approve-WsusUpdate -Action Install -TargetGroupName "Shane WSUS Production Computers"