# Windows Client:

# 1. Set Adapter to use DHCP  
Set-NetIPInterface -InterfaceAlias 'Ethernet' -Dhcp Enabled

# 2. Release and Renew IP to get DHCP Address
Ipconfig /release
Ipconfig /renew

# 3. Disable firewall
Set-NetFirewallProfile -Enabled False

# 4. Disable IPv6
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

# 5. Setting Hostname
Rename-Computer -NewName "ShaneClient"
Restart-Computer

# 6. Install PowerShell Version 7
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

# 7. Update PowerShell Help
Update-Help

# 8. Setting Time Zone
Set-TimeZone -Name "Eastern Standard Time"

# 9. Join the Client to the Domain 
Add-Computer -DomainCredential admin -Server "Shaneserver" -DomainName "ad.smhcomputers.com"
Restart-Computer