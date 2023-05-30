### Hyper-V Homelab Network Configuration:

Domain: Shane.local

Firewalls must be disabled in guest OS of VMs or networking will not work properly

# Things to do…
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

Server	OS	Services	Hostname	IP Address
Firewall/Gateway	pfSense	Firewall / VPN	ShaneFirewall	192.168.1.1
Windows Server	Windows Server 2019	DC 1 / DNS / DHCP / WSUS / SQL	ShaneServer	192.168.1.100
Windows Server 2	Windows Server 2019	DC 2 / File / Print / RRAS / RDS 	ShaneServer2	192.168.1.101
Windows Client	Windows 10 Pro	Client	ShaneClient	192.168.1.102
Linux Server	CentOS	-	ShaneLinux	192.168.1.103
NAS	TrueNAS	Network Storage	ShaneNAS	192.168.1.104

# Host:

Both Hyper-V Switches use Wireless Network Adapter

Internal Switch is for internal LAN communication: All Addresses are Static in Guest OS, One Internal Adapter per VM

External Switch is for external WAN communication: Address can fluctuate and is set via DHCP

# vSwitch Name	IP	Configuration
"Internal Switch"	192.168.1.1	New-NetIPAddress -InterfaceAlias "vEthernet (Internal Switch)" -IPAddress 192.168.1.1 -PrefixLength "24"
"External Switch"	DHCP	N/A - Address is Dynamic and changes when networks are changed

# Azure AD Connect:

Azure AD Connect is running on ShaneServer

Credentials: ShaneAdmin@Shane-Hartley.com - Tenant ID: 2b0884e8-3366-4d15-9fb6-1971df9f4fc0

# Network Diagram:



Network Diagram.drawio
![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/f5d7948a-c45a-481e-8b10-b4dcb40d6086)
