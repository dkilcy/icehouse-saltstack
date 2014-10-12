# Utility Node Setup

## Overview

Perform the following

* Install CentOS 6.5
	* Create devops user 
* Configure networking
* 24-hour Prime95 stress test hardware

Perform the following

* YUM update
* Install Salt Master
* Create SSH key for devops user
* Setup NFS server
* Create YUM repository
* Setup YUM to use local repository
* Install Additional Software
* Share YUM repository via NFS server
* SELinux and iptables
* Setup NTP Server
* Setup MySQL Client
* Create OpenStack passwords

### Install CentOS 6.5

1. Boot CentOS 6.5 x86_64 ISO from DVD via USB.  The "Welcome to CentOS 6.5!" screen should appear.
2. Select "Install or upgrade an existing system" and hit enter.  The system should boot off the DVD and another welcome screen appears with a "Disc Found" dialog
3. Select OK to test the media or skip to the next step
4. The CentOS 6 logo appears with a Next button in the lower right corner. Click Next
5. Select Language then click Next
6. Select Keyboard then click Next
7. Select "Basic Storage System" then click Next
8. Select "Fresh Install" then click Next
9. Enter the hostname "util-01.mgmt" then click Next.  
10. Select the Time Zone then click Next
11. Set the root password then click Next
12. Which type of installation would you like? Select "Use All Space".  Click the "Review and modify partitioning layout" checkbox at the lower left.  Click Next.
13. Highlight the "lv_home" volume group then click Delete and confirm to delete "vg_util01-lv_home" volume group.
14. Select the "lv_root" volume group then click Edit.  The Edit Logical Volume window appears.
15. In the Size (MB) list item, enter the value shown for Max Size.  Click OK.  This gives the root filesystem all of the available disk space minus the swap partition.  Click Next.
16. Write Changes to Disk
17. The disk is formatted
18. Boot loader option page appears, click Next
19. Installation Progress dialog appears then the type of install.  Select "Desktop" then click Next
20. Dependency Check dialog appears, then the Installation Starting dialog.  Wait for the install to finish.
21. Install finishes.  Disconnect DVD drive and reboot system
22. The CentOS logo appears.  Hit F2 to toggle between the logo and bootup messages
23. The Welcome screen will appear.  Click Foward button in the lower right corner
24. Agree to the license terms. Click Forward
25. Create user devops and set the password.  Click Forward
26. For Date and Time, select "synchronize time over the network" .  Click Forward.
27. For Kdump, unclick the "Enable Kdump" and click Finish.
28. A dialog appears prompting to reboot. Click Yes
29. Click OK.  The system reboots.
30. Gnone will start and the login dialog window will appear.  CentOS is installed.

### Configure Networking

1. Login as the devops user.
2. Edit /etc/sysconfig/network-scripts/ifcfg-eth0 
  Change below.
  ```
  ONBOOT=yes
  NM_CONTROLLED=no
  BOOTPROTO=static
  NETMASK=255.255.255.0
  IPADDR=10.0.0.5
  ```	
  
3. Edit /etc/sysconfig/network-scripts/ifcfg-eth1
  Change below.
  ```
  ONBOOT=yes
  NM_CONTROLLED=no
  BOOTPROTO=static
  NETMASK=255.255.255.0
  IPADDR=192.168.1.105
  ```
  
4. Edit /etc/sysconfig/network
  Add below.
  ```
  GATEWAY=192.168.1.1
  ```
  
5. Turn off Network Manager and turn on networking.
  Execute
  ```
  service NetworkManager stop
  service network start
  chkconfig NetworkManager off
  chkconfig network on
  ```
  
6. Check the configuration and ping the gateway 
  Execute
  ```
  ip route show
  ```
  
  You should see the following
  ```
  10.0.0.0/24 dev eth0  proto kernel  scope link  src 10.0.0.5 
  192.168.1.0/24 dev eth1  proto kernel  scope link  src 192.168.1.105 
  169.254.0.0/16 dev eth0  scope link  metric 1002 
  169.254.0.0/16 dev eth1  scope link  metric 1003 
  default via 192.168.1.1 dev eth1 
  ```
  
  Execute
  ```
  ifconfig -a
  ping 192.168.1.1
  ```
  
7. Set the nameserver in /etc/resolv.conf
  ```
  search mgmt pub
  nameserver 192.168.1.1
  ```
8. Test that DNS is working
  ```
  ping openstack.org
  ```

8. Create the /etc/hosts file to be used by all nodes

  Here is the /etc/host file
```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

###############################################################################
# Network:
# *.mgmt    - OpenStack Internal Network
# *.pub     - Public Network
# *.vm      - VM Traffic Network
###############################################################################

10.0.0.3        switch-01.mgmt  switch-01
10.0.0.4        switch-02.mgmt  switch-02

10.0.0.5        util-01.mgmt  util-01  salt  ntp
10.0.0.6        util-02.mgmt  util-02 

10.0.0.11       controller-01.mgmt  controller-01
10.0.0.12       controller-02.mgmt  controller-02

10.0.0.21       network-01.mgmt  network-01
10.0.0.22       network-02.mgmt  network-01

10.0.0.31       compute-01.mgmt  compute-01
10.0.0.32       compute-02.mgmt  compute-02
10.0.0.33       compute-03.mgmt  compute-03
10.0.0.34       compute-04.mgmt  compute-04

10.0.1.31       compute-01.vm    compute-01 
10.0.1.32       compute-02.vm    compute-02
10.0.1.33       compute-03.vm    compute-03
10.0.1.34       compute-04.vm    compute-04

192.168.1.32    dev-01.pub  dev-01
192.168.1.33    dev-02.pub  dev-02
192.168.1.34    dev-03.pub  dev-03

192.168.1.105   util-01.pub
192.168.1.106   util-02.pub

192.168.1.111   controller-01.pub
192.168.1.112   controller-02.pub
```

### YUM update

```
yum update
```

Reboot 

### Setup Salt Master on util-01
Execute the following commands as root
```
yum install salt-master

vi /etc/salt/master
#interface: 10.0.0.5

service salt-master restart
chkconfig salt-master on
```	
### Create SSH keypair for devops user

To allow devops to sudo without a password add the line
```
devops  ALL=(ALL)  NOPASSWD: ALL
``` 
using the visudo tool.

Switch to devops user 
```
su - devops
``` 
Create a public and private keypair for the user
```
ssh-keygen -t dsa -P '' -f /home/devops/.ssh/id_dsa
```	
To allow devops to be able to ssh to localhost, add the following
```
cat /home/devops/.ssh/id_dsa.pub > /home/devops/.ssh/authorized_keys
chmod 600 /home/devops/.ssh/authorized_keys
```	
### Create YUM repository
Create a local YUM mirror
Execute the following commands as root
```
yum install yum-plugin-priorities
yum install http://repos.fedorapeople.org/repos/openstack/openstack-icehouse/rdo-release-icehouse-3.noarch.rpm
yum install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

yum install createrepo
```	
Create the mirror repos
```
mkdir -p /data/nfs-share/repo/centos/6/x86_64
mkdir -p /data/nfs-share/repo/centos/6/x86_64/base
mkdir -p /data/nfs-share/repo/centos/6/x86_64/updates
mkdir -p /data/nfs-share/repo/centos/6/x86_64/extras
mkdir -p /data/nfs-share/repo/centos/6/x86_64/epel
mkdir -p /data/nfs-share/repo/centos/6/x86_64/openstack-icehouse

createrepo /data/nfs-share/repo/centos/6/x86_64/base
createrepo /data/nfs-share/repo/centos/6/x86_64/updates
createrepo /data/nfs-share/repo/centos/6/x86_64/extras
createrepo /data/nfs-share/repo/centos/6/x86_64/epel
createrepo /data/nfs-share/repo/centos/6/x86_64/openstack-icehouse
```
Create the /root/reposync.sh shell script
```
reposync -p /data/nfs-share/repo/centos/6/x86_64 --repoid=base
reposync -p /data/nfs-share/repo/centos/6/x86_64 --repoid=updates
reposync -p /data/nfs-share/repo/centos/6/x86_64 --repoid=extras
reposync -p /data/nfs-share/repo/centos/6/x86_64 --repoid=epel
reposync -p /data/nfs-share/repo/centos/6/x86_64 --repoid=openstack-icehouse
```	
Make the reposync.sh shell executable
```
chmod 755 /root/reposync.sh
```
Create a crontab entry for reposync.sh to run at 3:45 am every day
```
crontab -e
```	
Add the following entries to the crontab file
```    
# execute reposync.sh at 3:45AM
45 3 *  *  *  /root/reposync.sh > /root/reposync.out 2>&1
```

### SELinux and iptables
Do we really want to turn this off? No

Create a /root/firewall.sh script owned by root user.  
```
#!/bin/bash
#
# iptables configuration script
#
# Flush all current rules from iptables
#
 iptables -F
#
# Allow ICMP 
iptables -A INPUT -s 192.168.1.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -s 10.0.0.0/24 -p icmp --icmp-type echo-request -j ACCEPT
#
# Allow SSH connections on tcp port 22
# This is essential when working on remote servers via SSH to prevent locking yourself out of the system
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -s 10.0.0.0/24 --dport 22 -j ACCEPT
#
# Allow HTTP and HTTPS 
###iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 80 -j ACCEPT
###iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 443 -j ACCEPT
###iptables -A INPUT -p tcp -s 10.0.0.0/24 --dport 80 -j ACCEPT
###iptables -A INPUT -p tcp -s 10.0.0.0/24 --dport 443 -j ACCEPT
#
# Open ports for NFS4
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 2049 -j ACCEPT
iptables -A INPUT -p tcp -s 10.0.0.0/24 --dport 2049 -j ACCEPT
#
# Open ports for NTP
iptables -A INPUT -p udp -s 192.168.1.0/24 --dport 123 -j ACCEPT
iptables -A INPUT -p udp -s 10.0.0.0/24 --dport 123 -j ACCEPT
#
# Open ports for SaltStack
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 4505 -j ACCEPT
iptables -A INPUT -p tcp -s 10.0.0.0/24 --dport 4506 -j ACCEPT
#
#
# Set default policies for INPUT, FORWARD and OUTPUT chains
#
 iptables -P INPUT DROP
 iptables -P FORWARD DROP
 iptables -P OUTPUT ACCEPT
#
# Set access for localhost
#
 iptables -A INPUT -i lo -j ACCEPT
#
# Accept packets belonging to established and related connections
#
 iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#
# Save settings
#
 /sbin/service iptables save
#
# List rules
#
 iptables -L -v

```

Make sure to make it executable using chmod 700 firewall.sh

```
chmod 700 /root/firewall.sh
```

### Setup NFS server on util-01
Switch to the root user.
Create a directory for the NFS share
```
mkdir -p /data/nfs-share
```
Add the following entries to /etc/exports
```
/data/nfs-share 10.0.0.0/255.0.0.0(rw,sync,no_root_squash)
/data/nfs-share 192.168.1.0/255.255.255.0(rw,sync,no_root_squash)
```
Export the directory
```
exportfs -r
```
Add the following entries to /etc/hosts.allow
```
mountd: 10.0.0.0/255.0.0.0
mountd: 192.168.1.0/255.255.255.0
```
Add the following entries to /etc/hosts.deny
```
portmap:ALL
lockd:ALL
mountd:ALL
rquotad:ALL
statd:ALL
```
Start the NFS services and set them to start on reboot
```
service rpcbind restart
service nfs restart
service nfslock restart
	
chkconfig rpcbind on
chkconfig nfs on
chkconfig nfslock on
```

### Setup NTP on util-01

Keep this machine time synced with ntp from the network.
Everything else will sync with this machine.

Add to /etc/ntp.conf
```
restrict 10.0.0.0 mask 255.255.255.0 nomodify notrap
```

Start the NTP server and set it to start on reboot
```
service ntpd start
chkconfig ntpd on
```
Use the ntpq utility to verify that NTP server is working
```
ntpq -p
```

### Setup MySQL client on util-01
```
yum install mysql MySQL-python
```

### Create OpenStack passwords

To generate a password 
```
openssl rand -hex 10
```

Create a /home/devops/openstack/auth.sh file to be distributed to all the nodes 

```
export ADMIN_TOKEN=016389abda0579b560c0
export KEYSTONE_DBPASS=376ebc0ee6649544c178    #Database password of Identity service
export DEMO_PASS=6efd10a180784267be4c          #Password of user demo
export ADMIN_PASS=94bcee677185fee9c0bf         #Password of user admin
export GLANCE_DBPASS=6d44ef12b707316851f2      #Database password for Image Service
export GLANCE_PASS=d6b6ed7dac1e80c684e8        #Password of Image Service user glance
export NOVA_DBPASS=efc32b404d4f285c1a5a        #Database password for Compute service
export NOVA_PASS=a1b587dd687cff6a6dff          #Password of Compute service user nova
export DASH_DBPASS=f0baa153daac61a24102        #Database password for the dashboard
export CINDER_DBPASS=5680258bb2c2b4dee1ee      #Database password for the Block Storage service
export CINDER_PASS=c9f59d5c328fc3977297        #Password of Block Storage service user cinder
export NEUTRON_DBPASS=f06432c2e047666d99e3     #Database password for the Networking service
export NEUTRON_PASS=b398f7d80d20b77e238c       #Password of Networking service user neutron
export HEAT_DBPASS=a99a98179f6edb0ca113        #Database password for the Orchestration service
export HEAT_PASS=c6adaa597fbce9289f90          #Password of Orchestration service user heat
export CEILOMETER_DBPASS=55a0690b47fec6f98a31  #Database password for the Telemetry service
export CEILOMETER_PASS=d16c43e1a962a554c948    #Password of Telemetry service user ceilometer
export TROVE_DBPASS=8d2f0c22de016fe093f4       #Database password of Database service
export TROVE_PASS=18c357877c7120e6cca4         #Password of Database Service user trove
export METADATA_SECRET=0cb2bb516881d71eff88
```

To load the environment variables into the shell on a node
```
source /home/devops/openstack/auth.sh
```

## References

1. [Setup NFS client and server]
2. [Setup NTP client and server]

[Setup NFS client and server]: http://www.malaya-digital.org/setup-a-minimal-centos-6-64-bit-nfs-server/
[Setup NTP client and server]: http://www.cyberciti.biz/faq/rhel-fedora-centos-configure-ntp-client-server/


#### To disable SELinux and iptables:
1. Edit /etc/sysconfig/selinux and set SELINUX=disabled
2. Turn off SELinux and iptables
```
setenforce 0
service iptables stop
```

To reinstall broken package:
rpm -e --justdb --nodeps packagename

