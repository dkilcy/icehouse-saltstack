
# Networking Setup

This section explains how to install CentOS 6.5 on all of the nodes (controller, network and compute) ...
and configure networking. 

#### Domain name conventions

There are 3 networks.

Network                     | Domain	
--------------------------- | ------
OpenStack Internal Network  | .mgmt
Public Network              | .pub
VM Traffic Network          | .vm

#### IP Address and Ethernet assignments

For simplicity,
eth0 handles internal network
eth1 handles public network
eth2 handles VM network

Later on eth3 and eth4 will be used for bonding to increase network performance.

Node           | eth0          | eth1           | eth2           | eth3           | eth4
-------------- | ------------- | -------------- | -------------- | -------------- | -------------- |
workstation-01 | 10.0.0.5      | 192.168.1.5    |                |                |                |
workstation-02 | 10.0.0.6      | 192.168.1.6    |                |                |                |
controller-01  | 10.0.0.11     | 192.168.1.11   |                |                |                |
network-01     | 10.0.0.21     | External       | 10.0.1.21      |                |                |
compute-01     | 10.0.0.31     |                | 10.0.1.31      |                |                |
compute-02     | 10.0.0.32     |                | 10.0.1.32      |                |                |

## Overview

For each node (controller, network and compute):
* Install CentOS 6.5
* Configure Networking
* 24-hour Prine95 stress test hardware 


## Manual Install

### Controller

These steps are all performed using the console on the SuperMicros. Use a USB keyboard and VGA monitor connected to the backplane of the SuperMicro.

1. Boot CentOS 6.5 x86_64 ISO from DVD via USB. The "Welcome to CentOS 6.5!" screen should appear.
2. Select "Install or upgrade an existing system" and hit enter. The system should boot off the DVD and another welcome screen appears with a "Disc Found" dialog
3. Select OK to test the media or skip to the next step
4. The CentOS 6 logo appears with a Next button in the lower right corner. Click Next
5. Select Language then click Next
6. Select Keyboard then click Next
7. Select "Basic Storage System" then click Next
8. Select "Fresh Install" then click Next
9. Enter the hostname "util-01.mgmt" then click Next.
10. Select the Time Zone then click Next
11. Set the root password then click Next
12. Which type of installation would you like? Select "Use All Space". Click the "Review and modify partitioning layout"  checkbox at the lower left. Click Next.
13. Highlight the "lv_home" volume group then click Delete and confirm to delete "vg_util01-lv_home" volume group.
14. Select the "lv_root" volume group then click Edit. The Edit Logical Volume window appears.
15. In the Size (MB) list item, enter the value shown for Max Size. Click OK. This gives the root filesystem all of the available disk space minus the swap partition. Click Next.
16. Write Changes to Disk
17. The disk is formatted
18. Boot loader option page appears, click Next
19. Installation Progress dialog appears then the type of install. Select "Basic Server" then click Next
20. Dependency Check dialog appears, then the Installation Starting dialog. Wait for the install to finish.
21. Install finishes. Disconnect DVD drive and reboot system

### Configure Networking 

Edit /etc/sysconfig/network-scripts/ifcfg-eth0
```
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
NETMASK=255.255.255.0
IPADDR=10.0.0.11
```	
Edit /etc/sysconfig/network-scripts/ifcfg-eth1
```
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
NETMASK=255.255.255.0
IPADDR=192.168.1.111
```
Edit /etc/sysconfig/network
```
GATEWAY=192.168.1.1
```
Edit /etc/resolv.conf and setup DNS
```
search mgmt
nameserver 192.168.1.1
```
Restart the services
```
service network restart
chkconfig network on
```

#### Verify routes on controller-01
```
[root@controller-01 network-scripts]# ip route show
10.0.0.0/24 dev eth1  proto kernel  scope link  src 10.0.0.11 
192.168.1.0/24 dev eth0  proto kernel  scope link  src 192.168.1.101 
169.254.0.0/16 dev eth0  scope link  metric 1002 
169.254.0.0/16 dev eth1  scope link  metric 1003 
default via 192.168.1.1 dev eth0 
```

### Test network connectivity
```
ping 10.0.0.5
```

### Create the /etc/hosts file
```
scp 10.0.0.5:/etc/hosts /etc/hosts
```
### Test network services
```
ping util-01.mgmt
ping openstack.org
```

## Setup network node

### Install CentOS 6.5

1. Boot CentOS 6.5 x86_64 ISO from DVD via USB. The "Welcome to CentOS 6.5!" screen should appear.
2. Select "Install or upgrade an existing system" and hit enter. The system should boot off the DVD and another welcome screen appears with a "Disc Found" dialog
3. Select OK to test the media or skip to the next step
4. The CentOS 6 logo appears with a Next button in the lower right corner. Click Next
5. Select Language then click Next
6. Select Keyboard then click Next
7. Select "Basic Storage System" then click Next
8. Select "Fresh Install" then click Next
9. Enter the hostname "util-01.mgmt" then click Next.
10. Select the Time Zone then click Next
11. Set the root password then click Next
12. Which type of installation would you like? Select "Use All Space". Click the "Review and modify partitioning layout"  checkbox at the lower left. Click Next.
13. Highlight the "lv_home" volume group then click Delete and confirm to delete "vg_util01-lv_home" volume group.
14. Select the "lv_root" volume group then click Edit. The Edit Logical Volume window appears.
15. In the Size (MB) list item, enter the value shown for Max Size. Click OK. This gives the root filesystem all of the available disk space minus the swap partition. Click Next.
16. Write Changes to Disk
17. The disk is formatted
18. Boot loader option page appears, click Next
19. Installation Progress dialog appears then the type of install. Select "Basic Server" then click Next
20. Dependency Check dialog appears, then the Installation Starting dialog. Wait for the install to finish.
21. Install finishes. Disconnect DVD drive and reboot system

### Configure Networking on network-01

Edit /etc/sysconfig/network-scripts/ifcfg-eth0
```
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
NETMASK=255.255.255.0
IPADDR=10.0.0.21
```	
Edit /etc/sysconfig/network-scripts/ifcfg-eth1
```
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
```	
Edit /etc/sysconfig/network-scripts/ifcfg-eth2
```
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
NETMASK=255.255.255.0
IPADDR=10.0.1.21
```
Restart services
```
service network restart
service network on
```

### Verify routes on network-01

```
[root@network-01 openstack]# ip route show
10.0.0.0/24 dev eth0  proto kernel  scope link  src 10.0.0.21 
10.0.1.0/24 dev eth2  proto kernel  scope link  src 10.0.1.21 
169.254.0.0/16 dev eth0  scope link  metric 1002 
169.254.0.0/16 dev eth1  scope link  metric 1003 
169.254.0.0/16 dev eth2  scope link  metric 1005 ----
```
### Test network connectivity
```
ping 10.0.0.5
```

### Create the /etc/hosts file
```
scp 10.0.0.5:/etc/hosts /etc/hosts
```
### Test network services
```
ping util-01.mgmt
ping openstack.org
```

## Setup compute node

So far there has only been one physical disk installed so installation is straightforward.

### Install CentOS 6.5

1. Boot into the BIOS.  
  - When the SuperMicro boots, hold down the DEL key and enter the BIOS
  - From the BIOS menu, select Boot
  - Set the boot option from lowest to highest:
    - DVD Drive
    - 120 GB Intel Drve
    - UEFI
    - IBA
    - Disabled for the remaining options
  This makes sure that during the boot process it will check the correct drive to find the boot loader.
  - Select "Save & Exit" from the BIOS menu
  - Select "Save Changes and Reset" and reboot the system

1. Boot CentOS 6.5 x86_64 ISO from DVD via USB. The "Welcome to CentOS 6.5!" screen should appear.
2. Select "Install or upgrade an existing system" and hit enter. The system should boot off the DVD and another welcome screen appears with a "Disc Found" dialog
3. Select OK to test the media or skip to the next step
4. The CentOS 6 logo appears with a Next button in the lower right corner. Click Next
5. Select Language then click Next
6. Select Keyboard then click Next
7. Select "Basic Storage System" then click Next
8. Select "Fresh Install" then click Next
9. Enter the hostname "util-01.mgmt" then click Next.
10. Select the Time Zone then click Next
11. Set the root password then click Next
12. Which type of installation would you like? Select "Use All Space". Click the "Review and modify partitioning layout"  checkbox at the lower left. Click Next.
13. Move all the drives from the left to the right. **Make sure the bootload is selected on the 120 GB drive**. Click Next
14. The ?? screen appears.  Highlight "vg_compute01" then click Edit in the lower right corner.
  - Remove the sda1 and sdb1 drives from the volume group.  Click OK\
  - Click "LVM Storage Groups" then Create.   The Create Storage dialog appears.
  - Select "LVM Volume Group" then Create.  The Make LVM Volume Group dialog appears.
  - Set the Volume Group Name to vg_compute01_01.  Unselect sdb1.  Click OK
  - Under "Logical Volumes" Click Add.  Set the Mount point to /data1 partition.  
  - Repeat for other physical drive. Use vg_compute01_02 and /data2 for the volume group name and mount point.
  - Delete the lv_home under the vg_compute01 volume group.  The Confirm Delete dialog appears.  Click Delete
  - Select the lv_root volume group and click edit.  Add all the free space to the volume group. Click OK
  - Click Next.  If a Format Warning dialog appears click Format
  - The Writing Storage Configuration to Disk dialog appears.  Click Write changes to disk.  The system will begin formatting the drives.
13. Highlight the "lv_home" volume group then click Delete and confirm to delete "vg_util01-lv_home" volume group.
14. Select the "lv_root" volume group then click Edit. The Edit Logical Volume window appears.
15. In the Size (MB) list item, enter the value shown for Max Size. Click OK. This gives the root filesystem all of the available disk space minus the swap partition. Click Next.
16. Write Changes to Disk
17. The disk is formatted
18. Boot loader option page appears, click Next
19. Installation Progress dialog appears then the type of install. Select "Basic Server" then click Next
20. Dependency Check dialog appears, then the Installation Starting dialog. Wait for the install to finish.
21. Install finishes. Disconnect DVD drive and reboot system


### Configure Networking on Compute nodes

Edit /etc/sysconfig/network-scripts/ifcfg-eth0
```
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
NETMASK=255.255.255.0
IPADDR=10.0.0.31
```
Edit/etc/sysconfig/network-scripts/ifcfg-eth2
```	
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
NETMASK=255.255.255.0
IPADDR=10.0.1.31
```
Restart networking service
```
service network restart
```
Verify routes on compute-01
```
[root@compute-01 ~]# ip route show
10.0.0.0/24 dev eth0  proto kernel  scope link  src 10.0.0.31 
10.0.1.0/24 dev eth2  proto kernel  scope link  src 10.0.1.31 
169.254.0.0/16 dev eth0  scope link  metric 1002 
169.254.0.0/16 dev eth2  scope link  metric 1004 
```
### Test network connectivity
```
ping 10.0.0.5
```

### Create the /etc/hosts file
```
scp devops@10.0.0.5:/srv/salt/openstack-proj/hosts /etc/hosts
```
### Test network services
```
ping util-01.mgmt
```

On the controller, network and compute nodes do the following

* Disable SELinux and iptables 
* Install Salt Minion
* Create SSH key for devops user 
* Setup NFS Client
* Use YUM repo on NFS share
* Setup NTP Client
* Setup MySQL Client
* Setup Message Service
* Setup OpenStack passwords


### Next: common.md
