# Network Attached Storage:

1. Create Virtual Hard Drive for Operating System

2. Create Virtual Hard Drive for Storage
>(Boot Drive where OS is installed cannot be same Drive for Storage)

3. Create Separate Drive Mapping N on Host for Storage (N for NAS)

4. Connect Hyper-V Static Switch
>Interface Name: NASInterface
>IP: 192.168.1.104
>Subnet: 255.255.255.0

5. Configure DNS
>Domain: Shane
>DNS Name Server 1: 192.168.1.100
>DNS Name Server 2: N/A

6. Configure Default Route
>IP: 192.168.1.1

7. Admin WebGUI Username/Password: See Bitwarden

8. Create a new Pool
>Storage -> Pools
>Name: ShanePool

9. Create a SMB Share
>Sharing -> Windows Shares (SMB)
>Name: ShaneSMB

10. Create a new User
>Accounts -> Users
>Name: Shane

11. Edit ACL with Permissions

12. Map the SMB Share with Shane User Credentials
