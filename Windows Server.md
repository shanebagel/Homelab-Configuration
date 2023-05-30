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
![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/66663133-8abe-4d53-8c8a-583d4565c577)
