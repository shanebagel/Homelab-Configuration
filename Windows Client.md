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
![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/6fa62dea-a6f6-4a64-a91c-e383ab9ebfd5)
