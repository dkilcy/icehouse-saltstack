# Salt

* Create devops user
* Setup NTP client
* Setup MySQL client
* Setup QPID Message Service
* Distrubte OpenStack Tokens
* Setup SELinux and iptables policies
* 
For the controller:
* Setup MySQL server


On the utility node, check the salt keys waiting to be accepted.   controller-01.mgmt should be in the list
```
[root@util-01 ~]# salt-key -L
Accepted Keys:
Unaccepted Keys:
controller-01.mgmt
Rejected Keys:
[root@util-01 ~]# 
```
On the utility node, accept the key from controller-01 and add it to the salt managed systems
```
[root@util-01 ~]# salt-key -A
The following keys are going to be accepted:
Unaccepted Keys:
controller-01.mgmt
Proceed? [n/Y] 
Key for minion controller-01.mgmt accepted.
[root@util-01 ~]# salt '*' test.ping
controller-01.mgmt:
    True
[root@util-01 ~]# 
```

Create the /srv/salt directory
```
mkdir -p /srv/salt
```

### Create devops user

On the Salt master, create /srv/salt/users.sls
```
devops:
 user.present:
  - fullname: Dev Ops
  - shell: /bin/bash
  - home: /home/devops
  - password: $6$CUGzRMGauvFVkphz$P8nm/kplHcTWSOttcgE0kJGEMmkLlAPR8Y6iIH1t34E2gM9l8lO7GDy46qa7app50flB8oIgMsIg1/vKbPVHK0
     
AAAAB3NzaC1kc3MAAACBAOC1wqZotgRK/+xbFGkz+S+35TuyjSz5TE++iAHrY3PhiuyeWlQbOCuJr8rNCCrRQ20Lo8w2wJSNZ+MDtjx+kVYo85UrwPItBnEgZPYuUepEiUI7yklM9DZyorKvGsPyThUbCqHyIkF+6xHSp+p3wVoIw1mZhW3v0CtzzOCJ7AVxAAAAFQCesZv+7hE8n/ZthaVHKi+UraOPmwAAAIEAqe7AloRjMUfiYRH7jc4ub0cyPshTltqBAlb/32+LP2SOEtWR33vZyBljlRyX2v2GNVB0ew7uptZPOdZI2lsq5pcFdxxuIcd2IoHdUCcPgtXfk3YIvRyDfff/XqS6yU3mgT4zftB0urGViCtQqDPvNlLdlEiajHVweO7up+sjlC4AAACAMNPa4iLIpOGOMRzBeoIdlpu5j/UKB+8EmdU/SrIRfWko45rmCNT15OiLbf0xx8Fu8yVJek+MjGLNsJf3rEPWG27iOxmU97L6aLaV3pN7qh88C9JJekwd06KhKnq7axgtd/kM0i7xhtp4GmDgBwtVduj1Gf/5mmch4h9lrBxnuSY=:
 ssh_auth:
  - present
  - user: devops
  - enc: ssh-dss
  
/home/devops/openstack:
 file.directory:
  - user: devops
  - group: devops
  - mode: 755
  - makedirs: True

/home/devops/openstack/auth.sh:
 file.managed:
  - source: salt://openstack/auth.sh
  - mode: 644
  - user: devops
  - group: devops
  
/etc/sudoers:
 file.managed:
  - user: root
  - group: root
  - mode: 0440
  - source: salt://sudoers

```	

On the Salt master, create /srv/salt/sudoers 

```
Defaults    requiretty
Defaults   !visiblepw
Defaults    always_set_home
Defaults    env_reset
Defaults    env_keep =  "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR LS_COLORS"
Defaults    env_keep += "MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE"
Defaults    env_keep += "LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES"
Defaults    env_keep += "LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE"
Defaults    env_keep += "LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"
Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin
root	ALL=(ALL) 	ALL
devops  ALL=(ALL)  NOPASSWD: ALL
```

On the Salt master, execute
```
salt '*' state.sls users
```

On the Salt master, create /srv/salt/vim.sls
```
vim-enhanced:
 pkg.installed

/home/devops/.vimrc:
 file.managed:
  - source: salt://dotfiles/.vimrc
  - mode: 644
  - user: devops
  - group: devops
```
On the Salt master, create /srv/salt/dotfiles/.vim
```
:set expandtab
:set tabstop=4
```

On the Salt master, execute
```
salt '*' state.sls vim
```

### NTP Client

On the Salt master, create /srv/salt/ntp/ntp.conf
```
# For more information about this file, see the man pages
# ntp.conf(5), ntp_acc(5), ntp_auth(5), ntp_clock(5), ntp_misc(5), ntp_mon(5).

driftfile /var/lib/ntp/drift

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery

# Permit all access over the loopback interface.  This could
# be tightened as well, but to do so would effect some of
# the administrative functions.
restrict 127.0.0.1 
restrict -6 ::1

# Hosts on local network are less restricted.
#restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap

# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server ntp

#broadcast 192.168.1.255 autokey	# broadcast server
#broadcastclient			# broadcast client
#broadcast 224.0.1.1 autokey		# multicast server
#multicastclient 224.0.1.1		# multicast client
#manycastserver 239.255.254.254		# manycast server
#manycastclient 239.255.254.254 autokey # manycast client

# Enable public key cryptography.
#crypto

includefile /etc/ntp/crypto/pw

# Key file containing the keys and key identifiers used when operating
# with symmetric key cryptography. 
keys /etc/ntp/keys

# Specify the key identifiers which are trusted.
#trustedkey 4 8 42

# Specify the key identifier to use with the ntpdc utility.
#requestkey 8

# Specify the key identifier to use with the ntpq utility.
#controlkey 8

# Enable writing of statistics records.
#statistics clockstats cryptostats loopstats peerstats
```

create /srv/salt/ntp.sls
```
ntp:
  pkg:
    - installed
  service:
    - running

/etc/ntp.conf:
  file.managed:
    - source: salt://ntp/ntp.conf
    - user: root
    - group: root
    - mode: 644
```

Install the NTP client
```
salt '*' state.sls ntp
salt '*' service.restart ntpd
```

### MySQL Client

create /srv/salt/mysql.sls
```
mysql:
  pkg:
    - installed
    
MySQL-python:
  pkg:
    - installed
```

Install the MySQL client
```
salt '*' state.sls mysql
```

### QPID Message Service

```
qpid-cpp-server:
  pkg:
    - installed

qpidd:
  service:
    - running
    - require:
      - pkg: qpid-cpp-server

/etc/qpidd.conf:
  file.managed:
    - source: salt://qpidd/qpidd.conf
    - user: root
    - group: root
    - mode: 644
```

Start QPID Message Service
```
salt '*' state.sls qpid
salt '*' service.status qpidd
```

### Distribute OpenStack tokens



## Controller

### MySQL Server

create /srv/salt/mysql-server.sls
```
mysql-server:
 pkg:
  - installed

mysqld:
 service:
  - running
 
/etc/my.cnf:
 file.managed:
  - source: salt://mysql/my.cnf
  - user: mysql
  - group: mysql
  - mode: 644

install_db:
 cmd.wait:
  - name: "/usr/bin/mysql_install_db"

restart:
 cmd.wait:
  - name: service mysqld restart

```

Install the server
```
salt '*' state.sls mysql-server
salt '*' service.status mysqld
```

### SELinux and iptables

create /srv/salt/openstack-utils.sls
```
openstack-utils:
 pkg:
  - installed

openstack-selinux:
 pkg:
  - installed 
```


Create /root/firewall.sh script owned by root user.

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

Make sure to make it executable using chmod +x firewall.sh then execute to update iptables

```
chmod 700 firewall.sh
./firewall.sh
```


### References

[1]:[http://docs.saltstack.com/en/latest/topics/tutorials/starting_states.html]

### Other useful commands

```
cat /var/log/salt/master

salt '*' user.add devops
salt '*' file.sed /etc/ssh/sshd_config '#PermitRootLogin yes' 'PermitRootLogin no'
salt 'compute-02' hosts.add_host 192.168.1.101   controller-01.pub

salt '*' grains.item os
salt '*' grains.item host
salt '*' cmd.run 'cat /etc/*-release'

salt '*' service.status mysqld
salt '*' service.status ntpd

salt-call state.highstate
```
