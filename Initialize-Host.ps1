# Host:

# Both Hyper-V Switches share Wireless Network Adapter

# Internal Switch is for internal LAN communication: All Addresses are Static in Guest OS, One Adapter per VM - Priority value is placed on internal adapter

# External Switch is for external WAN communication: Address can fluctuate and is set via DHCP

# 1. Enable Hyper-V & Import Hyper-V Module
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
Import-Module Hyper-V

# 2. Retrieve list of commands available for the Hyper-V module
Get-Command -Module Hyper-V | Out-GridView

# 3. Create Virtual Switches
New-VMSwitch -Name "Internal Switch" -SwitchType Internal
New-VMSwitch -Name "External Switch" -NetAdapterName "Wi-Fi"

# 4. Apply IP address to Internal Switch
New-NetIPAddress -InterfaceAlias "vEthernet (Internal Switch)" -IPAddress 10.0.0.1 -PrefixLength 24

# 5. Create directories for ISO files
New-Item -ItemType Directory -Path "C:\Users\Shane\Documents\ISOs"

# 6. Download ISO files and name them accordingly:
# Windows Server 2019.iso
# Windows 10 Pro.iso

# 7. Set path for where ISOs are stored
$isos = @(
"C:\Users\Shane\Documents\ISOs\Windows Server 2019.iso",
"C:\Users\Shane\Documents\ISOs\Windows 10 Pro.iso"
)

# 8. Set path for new VHDs 
$vhds = @(
"C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\SHANESVR.vhdx",
"C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\SHANEWB.vhdx",
"C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\SHANEDB.vhdx",
"C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\SHANECLT.vhdx"
)

# 9. Create VMs
New-VM -Name "SHANESVR" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath $vhds[0] -NewVHDSizeBytes 32GB
New-VM -Name "SHANEWB" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath $vhds[1] -NewVHDSizeBytes 32GB
New-VM -Name "SHANEDB" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath $vhds[2] -NewVHDSizeBytes 64GB
New-VM -Name "SHANECLT" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath $vhds[3] -NewVHDSizeBytes 32GB

# 10. Add ISO images to boot from
Add-VMDvdDrive -VMName "SHANESVR" -Path $isos[0]
Add-VMDvdDrive -VMName "SHANEWB" -Path $isos[0]
Add-VMDvdDrive -VMName "SHANEDB" -Path $isos[0]
Add-VMDvdDrive -VMName "SHANECLT" -Path $isos[1]

# 11. Disable secure boot on VMs so they can boot from ISOs (Generation 1 VMs don't utilize secure boot)
Set-VMFirmware -VMName "SHANESVR" -EnableSecureBoot "Off"
Set-VMFirmware -VMName "SHANEWB" -EnableSecureBoot "Off"
Set-VMFirmware -VMName "SHANEDB" -EnableSecureBoot "Off"
Set-VMFirmware -VMName "SHANECLT" -EnableSecureBoot "Off"

# 12. Set boot order on VMs
$vms = @(
"SHANESVR",
"SHANEWB",
"SHANEDB",
"SHANECLT"
)

$dev1 = Get-VMFirmware -VMName $vms[0]
$dev2 = Get-VMFirmware -VMName $vms[1]
$dev3 = Get-VMFirmware -VMName $vms[2]
$dev4 = Get-VMFirmware -VMName $vms[3]

Set-VMFirmware -VMName $vms[0] -BootOrder $dev1.BootOrder[2], $dev1.BootOrder[1]
Set-VMFirmware -VMName $vms[1] -BootOrder $dev2.BootOrder[2], $dev2.BootOrder[1]
Set-VMFirmware -VMName $vms[2] -BootOrder $dev3.BootOrder[2], $dev3.BootOrder[1]
Set-VMFirmware -VMName $vms[3] -BootOrder $dev4.BootOrder[2], $dev4.BootOrder[1]

# 13. Add Internal & External Adapter
Get-VM $VMs | Add-VMNetworkAdapter -Name "External Adapter"
Get-VM $VMs | Add-VMNetworkAdapter -Name "Internal Adapter"

# 14. Attach adapters to the Hyper-V Internal Switch & External Switch
Connect-VMNetworkAdapter -VMName $VMs -Name "Internal Adapter" -SwitchName "Internal Switch"
Connect-VMNetworkAdapter -VMName $VMs -Name "External Adapter" -SwitchName "External Switch"

# 15. Set Static MAC on SHANECLT internal adapter (DHCP Reservation)
Set-VMNetworkAdapter -VMName "SHANECLT" -Name "Internal Adapter" -StaticMacAddress "00155D010161”

# 16. Boot VMs
Start-VM -VMName "SHANESVR"
Start-VM -VMName "SHANEWB"
Start-VM -VMName "SHANEDB"
Start-VM -VMName "SHANECLT"

# 17. Install OS

# 18. Power off VMs
Stop-VM -VMName "SHANESVR"
Stop-VM -VMName "SHANEWB"
Stop-VM -VMName "SHANEDB"
Stop-VM -VMName "SHANECLT"

# 19. Eject ISO images
Set-VMDvdDrive -VMName "SHANESVR" -Path $null
Set-VMDvdDrive -VMName "SHANEWB" -Path $null
Set-VMDvdDrive -VMName "SHANEDB" -Path $null
Set-VMDvdDrive -VMName "SHANECLT" -Path $null

# 20. Set boot order on VMs back to Hard Drive
$vms = @(
"SHANESVR",
"SHANEWB",
"SHANEDB",
"SHANECLT"
)

$dev1 = Get-VMFirmware -VMName $vms[0]
$dev2 = Get-VMFirmware -VMName $vms[1]
$dev3 = Get-VMFirmware -VMName $vms[2]
$dev4 = Get-VMFirmware -VMName $vms[3]

Set-VMFirmware -VMName $vms[0] -BootOrder $dev1.BootOrder[1], $dev1.BootOrder[0]
Set-VMFirmware -VMName $vms[1] -BootOrder $dev2.BootOrder[1], $dev2.BootOrder[0]
Set-VMFirmware -VMName $vms[2] -BootOrder $dev3.BootOrder[1], $dev3.BootOrder[0]
Set-VMFirmware -VMName $vms[3] -BootOrder $dev4.BootOrder[1], $dev4.BootOrder[0]

# 21. Create snapshots of each VM
Checkpoint-VM $VMs

# 22. Export each VM to an external drive
Export-VM -Name $VMs -Path "X:\"

# 23. Get a list of VMs
Get-VM | Format-List