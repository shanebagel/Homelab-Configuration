# Windows Client:

# 1. Set Adapter to use DHCP
Set-NetIPInterface -InterfaceAlias 'Ethernet' -Dhcp Enabled

# 2. Allow inbound ICMP traffic
New-NetFirewallRule -Name 'ICMPv4' -DisplayName "ICMPv4"

# 3. Setting Hostname
Rename-Computer -NewName "SHANECLT"
Restart-Computer

# 4. Disable IPv6 on adapter
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

# 5. Install PowerShell Version 7
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

# 6. Update PowerShell Help
Update-Help

# 7. Setting Time Zone
Set-TimeZone -Name "Central Standard Time"

# 8. Join the Client to the Domain 
Add-Computer -DomainCredential admin -Server "SHANESVR" -DomainName "AD.SMHCOMPUTERS.COM"
Restart-Computer

# 9. Set time to DC
w32tm /config /syncfromflags:domhier /update