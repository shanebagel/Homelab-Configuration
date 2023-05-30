### Hyper-V Homelab Network Configuration:

Domain: Shane.local

Firewalls must be disabled in guest OS of VMs or networking will not work properly

# Things to do…
Things to do…
Windows - Setup SQL Server

Windows - Setup RRAS Server

Windows - Setup RDS Server

Windows - Setup ADCS

Windows - Setup ADFS

Windows - Setup NPS Server

Windows - Setup IIS Server

Update Network Diagram to Include Internal/External Adapters

pfSense - Add More Rules, Setup VPN

Veeam - Backups

# VMs:

![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/c294daf4-1c0e-419d-a8bb-0634f264b052)

# Host:

Both Hyper-V Switches use Wireless Network Adapter

Internal Switch is for internal LAN communication: All Addresses are Static in Guest OS, One Internal Adapter per VM

External Switch is for external WAN communication: Address can fluctuate and is set via DHCP

vSwitch Name	IP	Configuration
"Internal Switch"	192.168.1.1	New-NetIPAddress -InterfaceAlias "vEthernet (Internal Switch)" -IPAddress 192.168.1.1 -PrefixLength "24"
"External Switch"	DHCP	N/A - Address is Dynamic and changes when networks are changed
![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/276cfcec-1aad-4ace-bd84-2101923cf127)


# vSwitch Name	IP	Configuration
"Internal Switch"	192.168.1.1	New-NetIPAddress -InterfaceAlias "vEthernet (Internal Switch)" -IPAddress 192.168.1.1 -PrefixLength "24"
"External Switch"	DHCP	N/A - Address is Dynamic and changes when networks are changed

# Azure AD Connect:

Azure AD Connect is running on ShaneServer

Credentials: ShaneAdmin@Shane-Hartley.com - Tenant ID: 2b0884e8-3366-4d15-9fb6-1971df9f4fc0

# Network Diagram:
![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/80ac2376-4e2e-4d71-a982-ad7b6be4202a)
