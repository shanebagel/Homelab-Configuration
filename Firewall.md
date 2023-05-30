# Firewall:

### Web Interface for pfSense Firewall
https://192.168.1.1:443

1. Connect Hyper-V External Switch

2. Configure WAN Interface for External Switch: DHCP

3. Connect Hyper-V Internal Switch

4. Configure LAN Interface for Internal Switch: Static IP

  >IP: 192.168.1.1  
  >Subnet: 24  
  >Gateway: N/A  


5. TCP/IP settings should automatically apply to the both interfaces.

### Interfaces:

  ![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/5b422407-42d5-4fb3-bb86-6064084d484b)

![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/b0640757-5d3d-470a-b145-9047ab7699cc)

6. Hostname: ShaneFirewall
7. Domain: Shane
8. DNS Resolution Behavior: Use local DNS (127.0.0.1), fall back to remote DNS Servers (Default)
9. Primary DNS Server: 8.8.8.8 (Google Public DNS) 
10. Secondary DNS Server: 192.168.1.100 (ShaneServer)
11. Uncheck "Allow DNS servers to be overridden by DHCP/PPP on WAN" 
12. Uncheck "Block private networks from entering via WAN"
13. Uncheck "Block non-Internet routed networks from entering WAN"
14. Time Server Hostname: 0.us.pool.ntp.org
15. Timezone: US/Eastern
16. Set Admin password
17. Reload 
18. Check "Enable Secure Shell"
19. SSH key Only: Public Key Only
20. Check "Allow Agent Forwarding"
21. SSH port: 22

### Interface Rule Directions:

Always configure Inbound (Ingress) Rules on WAN Interface - External Switch
Always configure Outbound Rules (Egress) on LAN Interface - Internal Switch 
OpenVPN <- Inbound (Egress) Rules 

![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/e1a94d82-1b0e-4a4f-8cc4-11353fe9f740)

### Default Firewall Rule:
Implicit Deny (If interface has no rules - all traffic will be blocked)


Structure of Firewall Rules:

Action: Pass/Block/Reject

Interface: LAN/WAN

Protocol: <Protocol>

Source: <Source of Network Traffic> 
  
Destination: <Destination of Network Traffic>

  
### Rules:

22. Edit LAN interface Rule 'Anti-Lockout Rule' to use port 443 HTTPS instead of HTTP
23. Remove LAN interface Rule 'Default allow LAN to any rule'
24. Remove LAN interface Rule 'Default allow LAN IPv6 to any rule'
25. Add LAN interface Rule to Allow Egress ICMP traffic - To permit pinging 
26. Add LAN interface Rule to Allow Egress SSH traffic - To permit SSH traffic 
27. Add LAN interface Rule to Allow Egress DNS traffic - To permit name resolution
28. Add LAN interface Rule to Allow Egress HTTP traffic - To permit egress HTTP traffic
29. Add LAN interface Rule to Allow Egress HTTPS traffic - To permit egress HTTPS traffic
30. Add LAN interface Rule to Allow Egress DNS over TLS traffic - To permit name resolution


![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/caf9f369-a65f-4f47-b53a-e1eea6cee9f7)

