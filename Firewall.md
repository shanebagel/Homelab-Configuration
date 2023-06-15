# Firewall:

Web Interface for pfSense Firewall
>http://192.168.1.1/

1. Connect Hyper-V External Switch

3. Connect Hyper-V Internal Switch

4. Assign interfaces hn0 and hn1 to either LAN / WAN according to MAC Address

5. WAN Interface - External Switch: DHCP (DHCP Reservation on Upstream Gateway)

6. LAN Interface - Internal Switch: Static - IP: 192.168.1.1 - Subnet: 24

7. Hostname: ShaneFirewall

8. Domain: smhomputers.com

9. Primary DNS Server: 8.8.8.8 (Google Public DNS) 

10. Check "Allow DNS server list to be overridden by DHCP/PPP on WAN"

11. Time Server Hostname: 0.us.pool.ntp.org

12. Timezone: US/Eastern

13. Under 'WAN Configuration'

14. Uncheck "Block private networks from entering via WAN"

15. Uncheck "Block non-Internet routed networks from entering via WAN"

16. Verify static IP on LAN interface

17. Set Admin password

18. Reload 

19. Under 'System' -> 'General Setup'

20. DNS Resolution Behavior: "Use local DNS (127.0.0.1), fall back to remote DNS Servers (Default)"

21. Under 'System' -> 'Advanced' -> 'Admin Access'

22. Check "HTTPS (SSL/TLS)"

23. Check "Enable Secure Shell"

24. SSH key Only: Public Key Only

25. Check "Allow Agent Forwarding"

26. SSH port: 22

27. Under 'Services' -> 'DHCP Server'

28. Enable DHCP server on LAN interface 


# Interfaces:
![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/9413fc56-6742-46ae-9199-7d421530f2d5)

# Interface Rule Directions:

Always configure Inbound (Ingress) Rules on WAN Interface - External Switch<br>
Always configure Outbound Rules (Egress) on LAN Interface - Internal Switch<br>
OpenVPN <- Inbound (Egress) Rules<br>
![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/d51134fc-cb2e-46a4-a82f-86f1fea129bc)


Default Firewall Rule:
>Implicit Deny (If interface has no rules - all traffic will be blocked)

# Structure of Firewall Rules:
Action: Pass/Block/Reject<br>
Interface: LAN/WAN<br>
Protocol: Protocol<br>
Source: Source of Network Traffic<br>
Destination: Destination of Network Traffic<br>

# Rules:
1. Remove LAN interface Rule 'Default allow LAN to any rule'
2. Remove LAN interface Rule 'Default allow LAN IPv6 to any rule'
3. Add LAN interface Rule to Allow Egress ICMP traffic - To permit pinging 
4. Add LAN interface Rule to Allow Egress SSH traffic - To permit SSH traffic 
5. Add LAN interface Rule to Allow Egress DNS traffic - To permit name resolution
6. Add LAN interface Rule to Allow Egress HTTP traffic - To permit egress HTTP traffic
7. Add LAN interface Rule to Allow Egress HTTPS traffic - To permit egress HTTPS traffic
8. Add LAN interface Rule to Allow Egress DNS over TLS traffic - To permit name resolution

![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/abfd4eba-94b8-4060-8fbc-93d87d42cfc4)

