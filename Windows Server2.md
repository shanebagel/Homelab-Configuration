# Windows Server 2:

1. Set DNS to Server 1

```
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.1.100"
```

2. Set Static IP, and Gateway to Host Adapter IP

```
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.101 -PrefixLength "24" -DefaultGateway 192.168.1.1
```

3. Disable firewall

```
Set-NetFirewallProfile -Enabled False
```

4. Disable IPv6

```
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
```

5. Setting Hostname

```
Rename-Computer -NewName "ShaneServer2"
Restart-Computer
```

6. Update PowerShell Help

```
Update-Help
```

7. Install ADDS and Management tools

```
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
```

8. Join Server 2 to Domain

```
Install-ADDSDomainController -DomainName "shane.local" -Credential (Get-Credential "Shane\Administrator")
```

9. Install PowerShell Version 7

```
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"
```

10. Install NuGet Package manager, prerequisite for installing modules

```
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
```

11. Installing Modules

```
Install-Module -Name $Modules -Force
```

12. Disable IE Enhanced Security 

```
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
```

13. Setting Time Zone

```
Set-TimeZone -Name "Eastern Standard Time"
```

14. Install Windows File Server Role

```
Install-WindowsFeature File-Services
```

15. Configuring and Mapping Network share for File Server

```
Set-Location C:\
New-Item -Type Directory -Name ShaneShare
New-SmbShare -Path C:\ShaneShare -Name "ShaneShare"
```

Creating a PS Session variable

```
$session = New-PSSession -ComputerName "shaneclient" -Credential(Get-Credential)
```

Creating a mapping of shared drive on Shaneclient to move files between server2 and client

```
Invoke-command -Session $session -ScriptBlock {New-PSDrive -Name "S" -PSProvider "FileSystem" -Root "\\ShaneServer3\Shaneshare"}
```


16. Install Print and Document Services 

```
Install-WindowsFeature Print-Services
```

Create Driver Directory

```
New-Item -Type Directory -Name "Drivers"
Set-Location Drivers
```

Disable Progress Preference 

```
$ProgressPreference= 'SilentlyContinue'
```

Download Driver

```
$url = "https://ftp.hp.com/pub/softlib/software12/COL53284/bi-128455-3/Full_Webpack-118-OJ8640_Full_Webpack.exe"
$path = "C:\Drivers\Driver.exe"
Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
```

Install Driver 

```
Start-Process -Wait -FilePath ".\Driver.exe" -ArgumentList "/S /v/qn" -PassThru
```

Get list of newly installed printer drivers

```
Get-PrinterDriver
```

>Add an External Hyper-V Adapter to reach LAN where printer is connected

Test network connectivity to printer

```
Test-Connection -ComputerName 192.168.1.125
```

Add TCP/IP printer port

```
Add-PrinterPort -Name "TCPPort:" -PrinterHostAddress "192.168.1.125"
```

Add printer via TCP/IP

```
Add-Printer -Name "HP Printer" -DriverName "HP Universal Printing PCL 6" -PortName "TCPPort:"
```

Validate printer was added

```
Get-Printer | Where-Object -Filter {$_.Name -eq "HP Printer"}
```

Share printer to other devices on network

```
Set-Printer -Name "HP Printer" -Shared $True -ShareName "HP Printer"
```

Validate printer share was added

```
Get-Printer | Where-Object -FilterScript {$_.ShareName -eq "HP Printer"}
```
