# Domain Controller:

# 1. Set primary DNS to Loopback Address
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "127.0.0.1"

# 2. Set Static IP, and Gateway IP to Hosts Internal Switch
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.0.0.10 -PrefixLength "24" -DefaultGateway 10.0.0.1

# 3. Allow inbound ICMP traffic
New-NetFirewallRule -Name 'ICMPv4' -DisplayName "ICMPv4"

# 4. Set External Adapter to take priority by updating Interface Metric
Set-NetIPInterface -InterfaceAlias "Ethernet 2" -InterfaceMetric 1

# 5. Configuration of NTP by setting DC to external NIST server time
function Set-NTPTime {
	Set-ItemProperty -path "HKLM:\system\CurrentControlSet\Services\W32Time\Config" -Name AnnounceFlags -Value 5 -Type DWord -Force
	Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name Type -Value NTP  -Force
	Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider" -Name Enabled -Value 0 -Type DWord -Force
	
	w32tm /config /manualpeerlist:"time.nist.gov" /syncfromflags:manual /reliable:yes /update
	w32tm /config /update
	Restart-Service w32time
	w32tm /resync /rediscover
	w32tm /resync
	w32tm /query /source
	Write-Host "Set NTP settings to external time server: time.nist.gov"
}
Set-NTPTime

# 6. Setting Hostname
Rename-Computer -NewName "SHANESVR"
Restart-Computer

# 7. Disable IPv6 on all adapters
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
Disable-NetAdapterBinding -Name "Ethernet 2" -ComponentID ms_tcpip6

# 8. Setting Time Zone
Set-TimeZone -Name "Central Standard Time"

# 9. Install ADDS and Management tools
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# 10. Test the configuration before installing the forest
Test-ADDSForestInstallation -DomainName AD.SMHCOMPUTERS.COM -InstallDns

# 11. Creating a new AD Forest with domain name ad.smhcomputers.com
Install-ADDSForest -DomainName AD.SMHCOMPUTERS.COM -InstallDNS

# 12. After reboot, check that AD is installed and Domain is configured
Get-ADDomainController

# 13. Install PowerShell Version 7
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

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

# Unprivileged User Account
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

# 17. Configuring DNS

# Add DNS Forwarder to 8.8.8.8 - Anything non-resolvable by local DNS server 'SHANESVR' gets sent out External Switch
Add-DNSServerForwarder 8.8.8.8 -PassThru; Get-DNSServerForwarder

# Add Forward Lookup Zone
Add-DNSServerPrimaryZone -Name "AD.SMHCOMPUTERS.COM" -ComputerName "SHANESVR" -ReplicationScope "Domain" -PassThru
Get-DNSServerZone -ZoneName "AD.SMHCOMPUTERS.COM"

# Add Reverse Lookup Zone
Add-DNSServerPrimaryZone -NetworkID "10.0.0/24" -ComputerName "SHANESVR" -ReplicationScope "Domain" -PassThru
Get-DNSServerZone -ZoneName "0.0.10.in-addr.arpa"

# Add A Records
Add-DNSServerResourceRecordA -Name "SHANESVR" -ZoneName "AD.SMHCOMPUTERS.COM" -IPv4Address "10.0.0.10" -ComputerName "SHANESVR"
Add-DNSServerResourceRecordA -Name "SHANEWB" -ZoneName "AD.SMHCOMPUTERS.COM" -IPv4Address "10.0.0.20" -ComputerName "SHANESVR"
Add-DNSServerResourceRecordA -Name "SHANEDB" -ZoneName "AD.SMHCOMPUTERS.COM" -IPv4Address "10.0.0.30" -ComputerName "SHANESVR"
Add-DNSServerResourceRecordA -Name "SHANECLT" -ZoneName "AD.SMHCOMPUTERS.COM" -IPv4Address "10.0.0.40" -ComputerName "SHANESVR"

# Add PTR Records
Add-DNSServerResourceRecordPtr -Name '10' -ZoneName '0.0.10.in-addr.arpa' -PtrDomainName 'SHANESVR.AD.SMHCOMPUTERS.COM' -ComputerName "SHANESVR"
Add-DNSServerResourceRecordPtr -Name '20' -ZoneName '0.0.10.in-addr.arpa' -PtrDomainName 'SHANEWB.AD.SMHCOMPUTERS.COM' -ComputerName "SHANESVR"
Add-DNSServerResourceRecordPtr -Name '30' -ZoneName '0.0.10.in-addr.arpa' -PtrDomainName 'SHANEDB.AD.SMHCOMPUTERS.COM' -ComputerName "SHANESVR"
Add-DNSServerResourceRecordPtr -Name '40' -ZoneName '0.0.10.in-addr.arpa' -PtrDomainName 'SHANECLT.AD.SMHCOMPUTERS.COM' -ComputerName "SHANESVR"

# Confirm DNS Records 
Get-DNSServerResourceRecord -ZoneName "AD.SMHCOMPUTERS.COM" -ComputerName "SHANESVR"

# 18. Installation and Configuration of DHCP
Install-WindowsFeature -Name dhcp -IncludeManagementTools

# Enable DHCP to communicate with AD
Add-DHCPServerInDC -DnsName SHANESVR.AD.SMHCOMPUTERS.COM

# Add a DHCP scope
Add-DhcpServerv4Scope -Name "ShaneScope" -StartRange 10.0.0.40 -EndRange 10.0.0.50 -SubnetMask 255.255.255.0

# Add Reservation to DHCP scope for SHANECLT - 10.0.0.40
Add-DhcpServerv4Reservation -Name "SHANECLT" -ScopeId 10.0.0.0 -IPAddress 10.0.0.40 -ClientID "00155D01d533" -Description "Reserved IP Address for SHANECLT"

# Add Gateway, Domain Name & DNS Server to DHCP Scope
Set-DhcpServerv4OptionValue -ComputerName "SHANESVR.AD.SMHCOMPUTERS.COM" -ScopeId 10.0.0.0 -DnsServer 10.0.0.10 -DnsDomain "AD.SMHCOMPUTERS.COM" -Router 10.0.0.1

# Reboot Server after DHCP Configuration 
Restart-Computer
