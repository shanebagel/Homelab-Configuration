# Windows Client:

# 1. Set Internal Adapter to use DHCP
Set-NetIPInterface -InterfaceAlias 'Ethernet' -Dhcp Enabled

# 2. Allow inbound ICMP traffic
New-NetFirewallRule -Name 'ICMPv4' -DisplayName "ICMPv4"

# 3. Set Internal Adapter to take priority by updating Interface Metric
Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 1

# 4. Setting Hostname
Rename-Computer -NewName "SHANECLT"
Restart-Computer

# 5. Disable IPv6
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

# 6. Disable IPv6 on all adapters
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
Disable-NetAdapterBinding -Name "Ethernet 2" -ComponentID ms_tcpip6

# 7. Install PowerShell Version 7
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

# 8. Update PowerShell Help
Update-Help

# 9. Setting Time Zone
Set-TimeZone -Name "Central Standard Time"

# 10. Join the Client to the Domain 
Add-Computer -DomainCredential admin -Server "SHANESVR" -DomainName "AD.SMHCOMPUTERS.COM"
Restart-Computer

# 11. Set time to DC
w32tm /config /syncfromflags:domhier /update
