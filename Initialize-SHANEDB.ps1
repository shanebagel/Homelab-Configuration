# Database Server:

# 1. Set internal adapter DNS to Domain Controller
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "10.0.0.10"

# 2. Set Static IP, and Gateway to Firewall
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.0.0.30 -PrefixLength "24" -DefaultGateway 10.0.0.1

# 3. Setting Hostname
Rename-Computer -NewName "SHANEDB"
Restart-Computer

# 4. Disable IPv6 on adapter
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

# 5. Allow inbound ICMP traffic
New-NetFirewallRule -Name 'ICMPv4' -DisplayName "ICMPv4"

# 6. Installation and Configuration of SQL Server PowerShell Module
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

# 7. Join the Server to the Domain 
Add-Computer -DomainCredential admin -Server "SHANESVR" -DomainName "AD.SMHCOMPUTERS.COM"
Restart-Computer

# 8. Set time to DC
w32tm /config /syncfromflags:domhier /update

# 9. Update PowerShell Help
Update-Help

# 10. Setting Time Zone
Set-TimeZone -Name "Central Standard Time"

# 11. Configure SSMS
# Set sa password
# Enable sa login