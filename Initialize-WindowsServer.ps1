# Windows Server 1:

# 1. Set primary DNS to Loopback Address and secondary DNS to pfSense
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "127.0.0.1,192.168.1.1"

# 2. Set Static IP, and Gateway IP to ShaneFirewall
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.100 -PrefixLength "24" -DefaultGateway 192.168.1.1

# 3. Disable Firewall
Set-NetFirewallProfile -Enabled False

# 4. Disable IPv6
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

# 5. Setting Hostname
Rename-Computer -NewName "ShaneServer"
Restart-Computer

# 6. Setting Time Zone
Set-TimeZone -Name "Eastern Standard Time"

# 7. Install ADDS and Management tools
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# 8. Test the configuration before installing the forest
Test-ADDSForestInstallation -DomainName ad.smhcomputers.com -InstallDns

# 9. Creating a new AD Forest with domain name ad.smhcomputers.com
Install-ADDSForest -DomainName ad.smhcomputers.com -InstallDNS

# 10. After reboot, check that AD is installed and Domain is configured
Get-ADDomainController

# 11. Install PowerShell Version 7
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

# 12. Creating a list of modules
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

# 13. Installing Modules
Install-Module -Name $Modules -Force

# 14. Update PowerShell Help
Update-Help

# 15. Disable IE Enhanced Security 
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

# 16. Creating OU, Users, and Groups

New-ADOrganizationalUnit -Name "Shane Users"
New-ADOrganizationalUnit -Name "Shane Computers"
$users = Get-ADOrganizationalUnit -LDAPFilter '(name=Shane Users)'

# Setting passwords for accounts
$secpass = Read-Host "Set password for accounts" -AsSecureString

# Regular User Account
New-ADUser -UserPrincipalName "Shane@smhcomputers.com" -Path $users.DistinguishedName -PasswordNeverExpires $True -Name "Shane Hartley" -Enabled $True -AccountPassword ($secpass) -SamAccountName "Shane"

# Admin User Account
New-ADUser -UserPrincipalName "Admin@smhcomputers.com" -Path $users.DistinguishedName -PasswordNeverExpires $True -Name "Admin" -Enabled $True -AccountPassword ($secpass) -SamAccountName "Admin"

# Create Root Key for Service Account
Add-KdsRootKey –EffectiveTime ((get-date).addhours(-10))     

# Service Account
New-ADServiceAccount -Path $users.DistinguishedName -Name "Service" -DNSHostName ad.smhcomputers.com

# Creating Security Group ShaneSG
New-ADGroup -Name "ShaneSG" -SamAccountName ShaneSG -GroupCategory Security -GroupScope Global -DisplayName "ShaneSG" -Path $users.DistinguishedName

# Adding admin user to default administrative SGs 
Add-ADGroupMember -Identity "Enterprise Admins" -Members "Admin"
Add-ADGroupMember -Identity "Domain Admins" -Members "Admin"
Add-ADGroupMember -Identity "Server Operators" -Members "Admin"

# Adding users created in the Shane OU to the Shane SG
Get-ADUser -filter * -searchbase $users.DistinguishedName | ForEach-Object {Add-AdGroupMember -Identity shaneSG -members $_.SamAccountName}

# Sync changes to Azure
Start-ADSyncSyncCycle -PolicyType Initial

# 17. Configuring DNS

# Add DNS Forwarder to 8.8.8.8 - Anything non-resolvable by local DNS server 'ShaneServer' uses Firewalls WAN interface to reach Googles Public DNS 
Add-DNSServerForwarder 8.8.8.8 -PassThru; Get-DNSServerForwarder

# Add Forward Lookup Zone
Add-DNSServerPrimaryZone -Name "ad.smhcomputers.com" -ComputerName "ShaneServer" -ReplicationScope "Domain" -PassThru
Get-DNSServerZone -ZoneName "ad.smhcomputers.com"

# Add Reverse Lookup Zone
Add-DNSServerPrimaryZone -NetworkID "192.168.1/24" -ComputerName "Shaneserver" -ReplicationScope "Domain" -PassThru
Get-DNSServerZone -ZoneName "1.168.192.in-addr.arpa"

# Add A Records
Add-DNSServerResourceRecordA -Name "Shanefirewall" -ZoneName "ad.smhcomputers.com" -IPv4Address "192.168.1.1" -ComputerName "ShaneServer"
Add-DNSServerResourceRecordA -Name "Shaneserver" -ZoneName "ad.smhcomputers.com" -IPv4Address "192.168.1.100" -ComputerName "ShaneServer"
Add-DNSServerResourceRecordA -Name "Shaneserver2" -ZoneName "ad.smhcomputers.com" -IPv4Address "192.168.1.101" -ComputerName "ShaneServer"
Add-DNSServerResourceRecordA -Name "Shaneclient" -ZoneName "ad.smhcomputers.com" -IPv4Address "192.168.1.102" -ComputerName "ShaneServer"

# Add PTR Records
Add-DNSServerResourceRecordPtr -Name '1' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'shanefirewall.smhcomputers.com' -ComputerName "shaneserver"
Add-DNSServerResourceRecordPtr -Name '100' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'Shaneserver.ad.smhcomputers.com' -ComputerName "shaneserver"
Add-DNSServerResourceRecordPtr -Name '101' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'shaneserver2.ad.smhcomputers.com' -ComputerName "shaneserver"
Add-DNSServerResourceRecordPtr -Name '102' -ZoneName '1.168.192.in-addr.arpa' -PtrDomainName 'shaneclient.ad.smhcomputers.com' -ComputerName "shaneserver"

# Confirm DNS Records 
Get-DNSServerResourceRecord -ZoneName "ad.smhcomputers.com" -ComputerName "shaneserver"

# 18. Installation and Configuration of DHCP
Install-WindowsFeature -Name dhcp -IncludeManagementTools

# Enable DHCP to communicate with AD
Add-DHCPServerInDC -DnsName ShaneServer.ad.smhcomputers.com

# Add a DHCP scope - .100 to .125
Add-DhcpServerv4Scope -Name "ShaneScope" -StartRange 192.168.1.100 -EndRange 192.168.1.125 -SubnetMask 255.255.255.0

# Add Reservation to DHCP scope for ShaneClient - 192.168.1.102
Add-DhcpServerv4Reservation -Name "ShaneReservation" -ScopeId 192.168.1.0 -IPAddress 192.168.1.102 -ClientID "00155D010161" -Description "Reserved IP Address for ShaneClient"

# Add Gateway, Domain Name & DNS Server to DHCP Scope
Set-DhcpServerv4OptionValue -ComputerName "shaneserver.ad.smhcomputers.com" -ScopeId 192.168.1.0 -DnsServer 192.168.1.100 -DnsDomain "ad.smhcomputers.com" -Router 192.168.1.1

# Reboot Server after DHCP Configuration 
Restart-Computer

# 19. Creating GPOs
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
Get-GPO -Name "Disable Control Panel" | New-GPLink -Target "OU=Shane Users,DC=ad,DC=smhcomputers,DC=com"
Get-GPO -Name "Disable Command Prompt" | New-GPLink -Target "OU=Shane Users,DC=ad,DC=smhcomputers,DC=com"
Get-GPO -Name "Mapped Drive" | New-GPLink -Target "OU=Shane Users,DC=ad,DC=smhcomputers,DC=com"
Get-GPO -Name "Mapped HP Printer" | New-GPLink -Target "OU=Shane Users,DC=ad,DC=smhcomputers,DC=com"

# Confirm all GPOs are applying to OU
$gpos = Get-GPInheritance -Target "OU=Shane Users,DC=shane,DC=local"; $gpos.GpoLinks | Format-Table 