# Homelab-Configuration

Hyper-V Homelab Network Configuration:

Domain: Shane.local

Firewalls must be disabled in guest OS of VMs or networking will not work properly

Things to do…
Windows - Setup SQL Server
Windows - Setup RRAS Server
Windows - Setup RDS Server
Windows - Setup ADCS
Windows - Setup ADFS
Windows - Setup NPS Server
Windows - Setup IIS Server
Update Network Diagram to Include Internal/External Adapters
pfSense - Add More Rules, Setup VPN
Veeam - Backups

VMs:

Server	OS	Services	Hostname	IP Address
Firewall/Gateway	pfSense	Firewall / VPN	ShaneFirewall	192.168.1.1
Windows Server	Windows Server 2019	DC 1 / DNS / DHCP / WSUS / SQL	ShaneServer	192.168.1.100
Windows Server 2	Windows Server 2019	DC 2 / File / Print / RRAS / RDS 	ShaneServer2	192.168.1.101
Windows Client	Windows 10 Pro	Client	ShaneClient	192.168.1.102
Linux Server	CentOS	-	ShaneLinux	192.168.1.103
NAS	TrueNAS	Network Storage	ShaneNAS	192.168.1.104

Host:

Both Hyper-V Switches use Wireless Network Adapter

Internal Switch is for internal LAN communication: All Addresses are Static in Guest OS, One Internal Adapter per VM

External Switch is for external WAN communication: Address can fluctuate and is set via DHCP

vSwitch Name	IP	Configuration
"Internal Switch"	192.168.1.1	New-NetIPAddress -InterfaceAlias "vEthernet (Internal Switch)" -IPAddress 192.168.1.1 -PrefixLength "24"
"External Switch"	DHCP	N/A - Address is Dynamic and changes when networks are changed

Azure AD Connect:

Azure AD Connect is running on ShaneServer

Credentials: ShaneAdmin@Shane-Hartley.com - Tenant ID: 2b0884e8-3366-4d15-9fb6-1971df9f4fc0

Network Diagram:



Network Diagram.drawio

Firewall:

Configuration
Web Interface for pfSense Firewall
https://192.168.1.1:443

1. Connect Hyper-V External Switch

2. Configure WAN Interface for External Switch: DHCP

3. Connect Hyper-V Internal Switch

4. Configure LAN Interface for Internal Switch: Static IP
IP: 192.168.1.1
Subnet: 24
Gateway: N/A

5. TCP/IP settings should automatically apply to the both interfaces.

Interfaces:



6. Hostname: ShaneFirewall
7. Domain: Shane
8. DNS Resolution Behavior: Use local DNS (127.0.0.1), fall back to remote DNS Servers (Default)
9. Primary DNS Server: 8.8.8.8 (Google Public DNS) 
10. Secondary DNS Server: 192.168.1.100 (ShaneServer)
11. Uncheck "Allow DNS servers to be overridden by DHCP/PPP on WAN" 
12. Uncheck "Block private networks from entering via WAN"
13. Uncheck "Block non-Internet routed networks from entering WAN"
14. Time Server Hostname: 0.us.pool.ntp.org
15. Timezone: US/Eastern
16. Set Admin password
17. Reload 
18. Check "Enable Secure Shell"
19. SSH key Only: Public Key Only
20. Check "Allow Agent Forwarding"
21. SSH port: 22

Interface Rule Directions:
Always configure Inbound (Ingress) Rules on WAN Interface - External Switch
Always configure Outbound Rules (Egress) on LAN Interface - Internal Switch 
OpenVPN <- Inbound (Egress) Rules 



Default Firewall Rule:
Implicit Deny (If interface has no rules - all traffic will be blocked)

Structure of Firewall Rules:
Action: Pass/Block/Reject
Interface: LAN/WAN
Protocol: <Protocol>
Source: <Source of Network Traffic>
Destination: <Destination of Network Traffic>

Rules:
22. Edit LAN interface Rule 'Anti-Lockout Rule' to use port 443 HTTPS instead of HTTP
23. Remove LAN interface Rule 'Default allow LAN to any rule'
24. Remove LAN interface Rule 'Default allow LAN IPv6 to any rule'
25. Add LAN interface Rule to Allow Egress ICMP traffic - To permit pinging 
26. Add LAN interface Rule to Allow Egress SSH traffic - To permit SSH traffic 
27. Add LAN interface Rule to Allow Egress DNS traffic - To permit name resolution
28. Add LAN interface Rule to Allow Egress HTTP traffic - To permit egress HTTP traffic
29. Add LAN interface Rule to Allow Egress HTTPS traffic - To permit egress HTTPS traffic
30. Add LAN interface Rule to Allow Egress DNS over TLS traffic - To permit name resolution




Windows Server 1:

Configuration
1. # Set DNS to Loopback Address
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "127.0.0.1"

2. # Set Static IP, and Gateway IP to ShaneFirewall
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.100 -PrefixLength "24" -DefaultGateway 192.168.1.1

3. # Disable Firewall
Set-NetFirewallProfile -Enabled False

4. # Disable IPv6
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

5. # Setting Hostname
Rename-Computer -NewName "ShaneServer"
Restart-Computer

6. # Update PowerShell Help
Update-Help

7. # Install ADDS and Management tools
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

8. # Test the configuration before installing the forest
Test-ADDSForestInstallation -DomainName shane.local -InstallDns

9. # Creating a new AD Forest with domain name Shane.local
Install-ADDSForest -DomainName shane.local -InstallDNS

10. # After reboot, check that AD is installed and Domain is configured
Get-ADDomainController

11. # Install PowerShell Version 7
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

12. # Install NuGet Package manager, prerequisite for installing modules
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

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

13. # Installing Modules
Install-Module -Name $Modules -Force

14. # Disable IE Enhanced Security 
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

15. # Setting Time Zone
Set-TimeZone -Name "Eastern Standard Time"

16. # Creating OU, Users, and Groups

# Creating OUs
New-ADOrganizationalUnit -Name "Shane Users"
New-ADOrganizationalUnit -Name "Shane Computers"
$users = Get-ADOrganizationalUnit -LDAPFilter '(name=Shane Users)'
$users.DistinguishedName

# Setting passwords for accounts
$secpass = Read-Host "Set password for accounts" -AsSecureString

# Creating accounts

# Regular User Account
New-ADUser -UserPrincipalName "Shane@shane.local" -Path $users.DistinguishedName -PasswordNeverExpires $True -Name "Shane Hartley" -Enabled $True -AccountPassword ($secpass) -SamAccountName "Shane"

# Admin User Account
New-ADUser -UserPrincipalName "ShaneAdmin@shane.local" -Path $users.DistinguishedName -PasswordNeverExpires $True -Name "Shane Hartley" -Enabled $True -AccountPassword ($secpass) -SamAccountName "ShaneAdmin"

# Service Account
New-ADServiceAccount -Path $users.DistinguishedName -Name "ShaneService" -DNSHostName ShaneServer.shane.local

# Creating Security Group ShaneSG
New-ADGroup -Name "ShaneSG" -SamAccountName ShaneSG -GroupCategory Security -GroupScope Global -DisplayName "ShaneSG" -Path $users.DistinguishedName

# Adding admin user to default SGs 
Add-ADGroupMember -Identity "Domain Admins" -Members "ShaneAdmin"
Add-ADGroupMember -Identity "Server Operators" -Members "ShaneAdmin"

# Adding users created in the Shane OU to the Shane SG
Get-ADUser -filter * -searchbase $users.DistinguishedName | ForEach-Object {Add-AdGroupMember -Identity shaneSG -members $_.SamAccountName}

17. # Configuring DNS

# Add DNS Forwarder to 8.8.8.8 - Anything non-resolvable by local DNS server 'ShaneServer' uses Firewalls WAN interface to reach Googles Public DNS 
Add-DNSServerForwarder 8.8.8.8 -PassThru; Get-DNSServerForwarder

# Add Forward Lookup Zone
Add-DNSServerPrimaryZone -Name "shane.local" -ComputerName "ShaneServer" -ReplicationScope "Domain" -PassThru
Get-DNSServerZone -ZoneName "Shane.local"

# Add Reverse Lookup Zone
Add-DNSServerPrimaryZone -NetworkID "192.168.1/24" -ComputerName "Shaneserver" -ReplicationScope "Domain" -PassThru
Get-DNSServerZone -ZoneName "1.168.192.in-addr.arpa"

# Add A Records
Add-DNSServerResourceRecordA -Name "Shaneserver" -ZoneName "Shane.local" -IPv4Address "192.168.1.100" -ComputerName "ShaneServer"
Add-DNSServerResourceRecordA -Name "Shaneserver2" -ZoneName "Shane.local" -IPv4Address "192.168.1.101" -ComputerName "ShaneServer"
Add-DNSServerResourceRecordA -Name "Shaneclient" -ZoneName "Shane.local" -IPv4Address "192.168.1.102" -ComputerName "ShaneServer"
Add-DNSServerResourceRecordA -Name "Shanelinux" -ZoneName "Shane.local" -IPv4Address "192.168.1.103" -ComputerName "ShaneServer"
Add-DNSServerResourceRecordA -Name "Shanenas" -ZoneName "Shane.local" -IPv4Address "192.168.1.104" -ComputerName "ShaneServer"
Add-DNSServerResourceRecordA -Name "Shanefirewall" -ZoneName "Shane.local" -IPv4Address "192.168.1.105" -ComputerName "ShaneServer"

# Add PTR Records
Add-DNSServerResourceRecordPtr -Name '100' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'Shaneserver.shane.local' -ComputerName "shaneserver"
Add-DNSServerResourceRecordPtr -Name '101' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'shaneserver2.shane.local' -ComputerName "shaneserver"
Add-DNSServerResourceRecordPtr -Name '102' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'shaneclient.shane.local' -ComputerName "shaneserver"
Add-DNSServerResourceRecordPtr -Name '103' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'shanelinux.shane.local' -ComputerName "shaneserver"
Add-DNSServerResourceRecordPtr -Name '104' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'shanenas.shane.local' -ComputerName "shaneserver"
Add-DNSServerResourceRecordPtr -Name '105' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'shanefirewall.shane.local' -ComputerName "shaneserver"

# Confirm DNS Records 
Get-DNSServerResourceRecord -ZoneName "<Zone>" -ComputerName <DNSServerName>

18. # Installation and Configuration of DHCP
Install-WindowsFeature -Name dhcp -IncludeManagementTools

# Enable DHCP to communicate with AD
Add-DHCPServerInDC -DnsName ShaneServer.shane.local

# Add a DHCP scope - .100 to .125
Add-DhcpServerv4Scope -Name "ShaneScope" -StartRange 192.168.1.100 -EndRange 192.168.1.125 -SubnetMask 255.255.255.0

# Add Reservation to DHCP scope for ShaneClient - 192.168.1.102
Add-DhcpServerv4Reservation -Name "ShaneReservation" -ScopeId 192.168.1.0 -IPAddress 192.168.1.102 -ClientID "<ShaneClientMAC>" -Description "Reserved IP Address for ShaneClient"

# Add Gateway, Domain Name & DNS Server to DHCP Scope
Set-DhcpServerv4OptionValue -ComputerName "shaneserver.shane.local" -ScopeId 192.168.1.0 -DnsServer 192.168.1.100 -DnsDomain "shane.local" -Router 192.168.1.1

# Reboot Server after DHCP Configuration 
Restart-Computer

19. # Creating GPOs
New-GPO -Name "Disable Control Panel"
New-GPO -Name "Disable Command Prompt"
New-GPO -Name "Mapped Drive"
New-GPO -Name "Mapped HP Printer"

# Configuring GPOs 
Set-GPRegistryValue -Name "Disable Control Panel" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoControlPanel" -Value 1 -Type DWORD
Set-GPRegistryValue -Name "Disable Command Prompt" -Key "HKCU\Software\Policies\Microsoft\Windows\System" -ValueName "DisableCMD" -Value 1 -Type DWORD

# Manually Create GPOs for Printer/Drive Maps
# User Configuration\Preferences\Control Panel Settings\Printers\Shared Printer (Name: \\shaneserver2\HP Printer)
# User Configuration\Preferences\Windows Settings\Drive Maps\Drive Map (Drive: S \\shaneserver2\ShaneShare)

# Applying the GPO to OU "Shane Users" which contains the Client PC
Get-GPO -Name "Disable Control Panel" | New-GPLink -Target "OU=Shane Users,DC=shane,DC=local"
Get-GPO -Name "Disable Command Prompt" | New-GPLink -Target "OU=Shane Users,DC=shane,DC=local"
Get-GPO -Name "Mapped Drive" | New-GPLink -Target "OU=Shane Users,DC=shane,DC=local"
Get-GPO -Name "Mapped HP Printer" | New-GPLink -Target "OU=Shane Users,DC=shane,DC=local"

# Confirm all GPOs are applying to OU
$gpos = Get-GPInheritance -Target "OU=Shane Users,DC=shane,DC=local"; $gpos.GpoLinks | Format-Table 

20. # WSUS Installation and Configuration - Local Windows Database
Install-WindowsFeature -Name UpdateServices, UpdateServices-Ui , UpdateServices-WidDB -IncludeManagementTools

# Set Database to WSUS Directory 
Set-Location "C:\Program Files\Update Services\Tools"
.\WsusUtil.exe PostInstall CONTENT_DIR=C:\WSUS

# Connect to WSUS Database
[void][reflection.assembly]::LoadWithPartialName(“Microsoft.UpdateServices.Administration”)
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer('shaneserver',$False,8530)

# Add "Shane WSUS Production Computers" Group

# Configuring GPO to point computers at WSUS server
# Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Update\Configure Automatic Updates
# Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Update\Specify intranet Microsoft update service location

# Enable both policies - Set the WSUS Server that clients will use for updates via GPO
# http://ShaneServer.shane.local:8530

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

21. # Installation and Configuration of SQL Server PowerShell Module
Install-Module SQLServer 

# Installation of dbatools
Install-Module dbatools 

New-Item -Type Directory -Name "SQL"
Set-Location "C:\SQL"
$path = "C:\SQL"

$url = https://aka.ms/ssmsfullsetup
Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing

$url2= https://go.microsoft.com/fwlink/p/?linkid=2216019&clcid=0x409&culture=en-us&country=us
Invoke-WebRequest -Uri $url2 -OutFile $path -UseBasicParsing

# Installation of SQL Server Express and SSMS
Start-Process -Wait -FilePath ".\SSMS-Setup-ENU.exe" -ArgumentList "/S /v/qn" -PassThru
Start-Process -Wait -FilePath ".\SQL2022-SSEI-Expr.exe" -ArgumentList "/S /v/qn" -PassThru

Windows Server 2:

Configuration
1. # Set DNS to Server 1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.1.100"

2. # Set Static IP, and Gateway to Host Adapter IP
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.101 -PrefixLength "24" -DefaultGateway 192.168.1.1

3. # Disable firewall
Set-NetFirewallProfile -Enabled False

4. # Disable IPv6
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

5. # Setting Hostname
Rename-Computer -NewName "ShaneServer2"
Restart-Computer

6. # Update PowerShell Help
Update-Help

7. # Install ADDS and Management tools
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

8. # Join Server 2 to Domain
Install-ADDSDomainController -DomainName "shane.local" -Credential (Get-Credential "Shane\Administrator")

9. # Install PowerShell Version 7
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

10. # Install NuGet Package manager, prerequisite for installing modules
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

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

11. # Installing Modules
Install-Module -Name $Modules -Force

12. # Disable IE Enhanced Security 
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

13. # Setting Time Zone
Set-TimeZone -Name "Eastern Standard Time"

14. # Install Windows File Server Role
Install-WindowsFeature File-Services

15. # Configuring and Mapping Network share for File Server
Set-Location C:\
New-Item -Type Directory -Name ShaneShare
New-SmbShare -Path C:\ShaneShare -Name "ShaneShare"

# Creating a PS Session variable
$session = New-PSSession -ComputerName "shaneclient" -Credential(Get-Credential)

# Creating a mapping of shared drive on Shaneclient to move files between server2 and client
Invoke-command -Session $session -ScriptBlock {New-PSDrive -Name "S" -PSProvider "FileSystem" -Root "\\ShaneServer3\Shaneshare"}

16. # Install Print and Document Services 
Install-WindowsFeature Print-Services

# Create Driver Directory
New-Item -Type Directory -Name "Drivers"
Set-Location Drivers

# Disable Progress Preference 
$ProgressPreference= 'SilentlyContinue'

# Download Driver
$url = "https://ftp.hp.com/pub/softlib/software12/COL53284/bi-128455-3/Full_Webpack-118-OJ8640_Full_Webpack.exe"
$path = "C:\Drivers\Driver.exe"
Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing

# Install Driver 
Start-Process -Wait -FilePath ".\Driver.exe" -ArgumentList "/S /v/qn" -PassThru

# Get list of newly installed printer drivers
Get-PrinterDriver

# Add an External Hyper-V Adapter to reach LAN where printer is connected

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

Windows Client:

Configuration
1. # Set Adapter to use DHCP  
Set-NetIPInterface -InterfaceAlias 'Ethernet' -Dhcp Enabled

2. # Release and Renew IP to get DHCP Address
Ipconfig /release
Ipconfig /renew

3. # Disable firewall
Set-NetFirewallProfile -Enabled False

4. # Disable IPv6
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

5. # Setting Hostname
Rename-Computer -NewName "ShaneClient"
Restart-Computer

6. # Update PowerShell Help
Update-Help

7. # Install PowerShell Version 7
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

8. # Install NuGet Package manager, prerequisite for installing modules
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

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

9. # Installing Modules
Install-Module -Name $Modules -Force

10. # Setting Time Zone
Set-TimeZone -Name "Eastern Standard Time"

11. # Join the Client to the Domain 
Add-Computer -DomainCredential administrator -Server "Shaneserver" -DomainName "Shane.local"
Restart-Computer

Linux Server:

Configuration
1. # Add Internal Switch adapter

2. # Add "Shane" user to Wheel (Admin) Group
su --login root
usermod -a -G wheel Shane

3. # Set Static IP on Internal Network Adapter using NMCLI - Point at ShaneServer for DNS
sudo nmcli connection add type ethernet ifname eth0 ip4 192.168.1.103/24 gw4 192.168.1.1 ipv4.dns 192.168.1.100

4. # Validate Route Table entries and Default Gateway 
Route


5. # Update resolution on VM
sudo grubby --update-kernel=ALL --args="video=hyperv_fb:1920x1080"
reboot

6. # Keep man pages on screen after closing 
cd ~
sudo echo ' export LESS="-X"' >> .bashrc 
exec bash 

7. # Update Hosts file 
Sudo /bin/sh -c 'echo "192.168.1.1 shanefirewall shanefirewall.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.100 shaneserver shaneserver.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.101 shaneserver2 shaneserver2.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.102 shaneclient shaneclient.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.103 shanelinux shanelinux.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.104 shanenas shanenas.shane.local" >> /etc/hosts

8. # Update system and upgrade packages
Su --login root
Yum update && yum upgrade -y
Exit

NAS:

Configuration
1. Create Virtual Hard Drive for Operating System

2. Create Virtual Hard Drive for Storage
(Boot Drive where OS is installed cannot be same Drive for Storage)

3. Create Separate Drive Mapping N on Host for Storage (N for NAS)

4. Connect Hyper-V Static Switch
Interface Name: NASInterface
IP: 192.168.1.104
Subnet: 255.255.255.0

5. Configure DNS
Domain: Shane
DNS Name Server 1: 192.168.1.100
DNS Name Server 2: N/A

6. Configure Default Route
IP: 192.168.1.1

7. Admin WebGUI Username/Password: See Bitwarden

8. Create a new Pool
Storage -> Pools
Name: ShanePool

9. Create a SMB Share
Sharing -> Windows Shares (SMB)
Name: ShaneSMB

10. Create a new User
Accounts -> Users
Name: Shane

11. Edit ACL with Permissions

12. Map the SMB Share with Shane User Credentials
![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/1ccdcc96-6d08-474e-ae45-c84a559f8bb9)
