# Windows Client:

# 1. Set Adapter to use DHCP

Set-NetIPInterface -InterfaceAlias 'Ethernet' -Dhcp Enabled

# 3. Release and Renew IP to get DHCP Address

Ipconfig /release
Ipconfig /renew

# 4. Disable firewall

Set-NetFirewallProfile -Enabled False

# 5. Disable IPv6

Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

# 6. Setting Hostname

Rename-Computer -NewName "ShaneClient"
Restart-Computer

# 7. Install PowerShell Version 7

Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"

# 8. Update PowerShell Help

Update-Help

# 9. Setting Time Zone

Set-TimeZone -Name "Eastern Standard Time"

# 10. Join the Client to the Domain 

Add-Computer -DomainCredential admin -Server "Shaneserver" -DomainName "ad.smhcomputers.com"
Restart-Computer