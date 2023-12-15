# Web Server:

# 1. Set internal adapter DNS to Domain Controller
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "10.0.0.10"

# 2. Set Static IP, and Gateway IP to Hosts Internal Switch
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.0.0.20 -PrefixLength "24" -DefaultGateway 10.0.0.1

# 3. Setting Hostname
Rename-Computer -NewName "SHANEWB"
Restart-Computer

# 4. Disable IPv6 on all adapters
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
Disable-NetAdapterBinding -Name "Ethernet 2" -ComponentID ms_tcpip6

# 5. Allow inbound ICMP traffic
New-NetFirewallRule -Name 'ICMPv4' -DisplayName "ICMPv4"

# 6. Set Internal Adapter to take priority by updating Interface Metric
Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 1

# 7. Installation of IIS role and IIS module
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Install-Module -Name IISAdministration 

# 8. Join the Server to the Domain 
Add-Computer -DomainCredential admin -Server "SHANESVR" -DomainName "AD.SMHCOMPUTERS.COM"
Restart-Computer

# 9. Set time to DC
w32tm /config /syncfromflags:domhier /update

# 10. Update PowerShell Help
Update-Help

# 11. Setting Time Zone
Set-TimeZone -Name "Central Standard Time"
