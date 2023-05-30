Linux Server:

Configuration
1. # Add Internal Switch adapter

2. # Add "Shane" user to Wheel (Admin) Group
su --login root
usermod -a -G wheel Shane

3. # Set Static IP on Internal Network Adapter using NMCLI - Point at ShaneServer for DNS
sudo nmcli connection add type ethernet ifname eth0 ip4 192.168.1.103/24 gw4 192.168.1.1 ipv4.dns 192.168.1.100

4. # Validate Route Table entries and Default Gateway 
Route


5. # Update resolution on VM
sudo grubby --update-kernel=ALL --args="video=hyperv_fb:1920x1080"
reboot

6. # Keep man pages on screen after closing 
cd ~
sudo echo ' export LESS="-X"' >> .bashrc 
exec bash 

7. # Update Hosts file 
Sudo /bin/sh -c 'echo "192.168.1.1 shanefirewall shanefirewall.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.100 shaneserver shaneserver.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.101 shaneserver2 shaneserver2.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.102 shaneclient shaneclient.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.103 shanelinux shanelinux.shane.local" >> /etc/hosts
Sudo /bin/sh -c 'echo "192.168.1.104 shanenas shanenas.shane.local" >> /etc/hosts

8. # Update system and upgrade packages
Su --login root
Yum update && yum upgrade -y
Exit
![image](https://github.com/shanebagel/Homelab-Configuration/assets/99091402/91a33dbc-2e01-49af-83aa-9e335c4535f5)
