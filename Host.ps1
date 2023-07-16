# Host:

# Both Hyper-V Switches share Wireless Network Adapter

# Internal Switch is for internal LAN communication: All Addresses are Static in Guest OS, One Adapter per VM

# External Switch is for external WAN communication: Address can fluctuate and is set via DHCP on WAN interface of pfSense Firewall

# 1. Enable Hyper-V

Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

# 2. Retrieve list of commands available for the Hyper-V module

Get-Command -Module Hyper-V | Out-GridView

# 3. Create Virtual Switches

New-VMSwitch -Name "Internal Switch" -SwitchType Internal
New-VMSwitch -Name "External Switch" -NetAdapterName "Wi-Fi"

# 4. The virtual switch must be configured with a static IP address - Shares it's IP with the pfSense Firewalls LAN interface

New-NetIPAddress -InterfaceAlias "vEthernet (Internal Switch)" -IPAddress 192.168.1.1 -PrefixLength 24

# 5. Create directories for ISOs/VHD files

New-Item -ItemType Directory -Path "C:\Users\Shane\Documents\ISOs"
New-Item -ItemType Directory -Path "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks"

# 6. Download ISO files and name them accordingly:

# pfSense.iso
# Windows Server 2019.iso
# Windows 10 Pro.iso

# 7. Set path for where ISOs are stored

$isos = @(
"C:\Users\Shane\Documents\ISOs\pfSense.iso",
"C:\Users\Shane\Documents\ISOs\Windows Server 2019.iso",
"C:\Users\Shane\Documents\ISOs\Windows 10 Pro.iso",
)

# 8. Set path for new VHDs 

$vhds = @(
"C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\ShaneFirewall.vhdx",
"C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\ShaneServer.vhdx",
"C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\ShaneServer2.vhdx",
"C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\ShaneClient.vhdx",
)

# 9. Create VMs

New-VM -Name "ShaneFirewall" -Generation 1 -MemoryStartupBytes 2GB -NewVHDPath $vhds[0] -NewVHDSizeBytes 16GB
New-VM -Name "ShaneServer" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath $vhds[1] -NewVHDSizeBytes 48GB
New-VM -Name "ShaneServer2" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath $vhds[2] -NewVHDSizeBytes 48GB
New-VM -Name "ShaneClient" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath $vhds[3] -NewVHDSizeBytes 24GB

# 10. Add ISO images to boot from

Add-VMDvdDrive -VMName "ShaneFirewall" -Path $isos[0]
Add-VMDvdDrive -VMName "ShaneServer" -Path $isos[1]
Add-VMDvdDrive -VMName "ShaneServer2" -Path $isos[1]
Add-VMDvdDrive -VMName "ShaneClient" -Path $isos[2]

# 11. Disable secure boot on VMs so they can boot from ISOs (Generation 1 VMs don't utilize secure boot)

Set-VMFirmware -VMName "ShaneServer" -EnableSecureBoot "Off"
Set-VMFirmware -VMName "ShaneServer2" -EnableSecureBoot "Off"
Set-VMFirmware -VMName "ShaneClient" -EnableSecureBoot "Off"

# 12. Set boot order on VMs (Generation 1 VMs default to CD for boot order)

$vms = @(
"ShaneServer",
"ShaneServer2",
"ShaneClient",
"ShaneFirewall"
)

$dev1 = Get-VMFirmware -VMName $vms[0]
$dev2 = Get-VMFirmware -VMName $vms[1]
$dev3 = Get-VMFirmware -VMName $vms[2]

Set-VMFirmware -VMName $vms[0] -BootOrder $dev1.BootOrder[2], $dev1.BootOrder[1]
Set-VMFirmware -VMName $vms[1] -BootOrder $dev2.BootOrder[2], $dev2.BootOrder[1]
Set-VMFirmware -VMName $vms[2] -BootOrder $dev3.BootOrder[2], $dev3.BootOrder[1]


# 13. Connect all Adapters to the Hyper-V Internal Switch

Connect-VMNetworkAdapter -VMName $vms -Name "Network Adapter" -SwitchName "Internal Switch"

# 14. Connect External Switch to Firewall and Default Switch to ShaneServer2 to be able to reach LAN Printer

Add-VMNetworkAdapter -VMName "ShaneFirewall" -SwitchName "External Switch" -Name "Network Adapter 2"
Add-VMNetworkAdapter -VMName "ShaneServer2" -SwitchName "Default Switch" -Name "Network Adapter 2"

# 15. Set Static MAC on WAN Firewall Adapter so it doesn't change (Need this for IP passthrough)

Set-VMNetworkAdapter -VMName "ShaneFirewall" -Name "Network Adapter 2" -StaticMacAddress "00155D010155”

# 16. Set Static MAC on ShaneClient internal adapter (Need this for DHCP reservation)

Set-VMNetworkAdapter -VMName "ShaneClient" -Name "Network Adapter" -StaticMacAddress "00155D010161”

# 17. Boot VMs

Start-VM -VMName "ShaneFirewall"
Start-VM -VMName "ShaneServer"
Start-VM -VMName "ShaneServer2"
Start-VM -VMName "ShaneClient"

# 18. Install OS

# 19. Power off VMs

Stop-VM -VMName "ShaneFirewall"
Stop-VM -VMName "ShaneServer"
Stop-VM -VMName "ShaneServer2"
Stop-VM -VMName "ShaneClient"

# 20. Eject ISO images

Set-VMDvdDrive -VMName "ShaneFirewall" -Path $null
Set-VMDvdDrive -VMName "ShaneServer" -Path $null
Set-VMDvdDrive -VMName "ShaneServer2" -Path $null
Set-VMDvdDrive -VMName "ShaneClient" -Path $null

# 21. Set boot order on VMs back to Hard Drive

$vms = @(
"ShaneFirewall",
"ShaneServer",
"ShaneServer2",
"ShaneClient"
)

$dev1 = Get-VMFirmware -VMName $vms[1]
$dev2 = Get-VMFirmware -VMName $vms[2]
$dev3 = Get-VMFirmware -VMName $vms[3]

Get-VMBios -VMname $vms[0] | Set-VMBios -StartupOrder @("IDE", "Floppy", "LegacyNetworkAdapter", "CD")
Set-VMFirmware -VMName $vms[1] -BootOrder $dev1.BootOrder[1], $dev2.BootOrder[0]
Set-VMFirmware -VMName $vms[2] -BootOrder $dev2.BootOrder[1], $dev3.BootOrder[0]
Set-VMFirmware -VMName $vms[3] -BootOrder $dev3.BootOrder[1], $dev4.BootOrder[0]

# 22. Connect to each VM individually to configure

Enter-PSSession-VMName "ShaneServer"

# 23. Create snapshots of each VM

Checkpoint-VM $vms

# 24. Export each VM to external drive

Export-VM -Name $vms -Path "X:\"

# 25. Get a list of VMs

Get-VM | Format-List