# Common

* SELinux and iptables
* Setup NFS Client
* YUM Update
* Install Salt Minion 

After the Salt minion is installed, the utility node is used perform the rest of the installation.
This includes
* Setup devops user
* Setup NTP Client
* Setup MySQL Client
* Setup QPID Message Service
* Distribute OpenStack tokens

### Setup NFS client 

```
mkdir -p /data/nfs-share
mount -t nfs4 util-01.mgmt:/data/nfs-share /data/nfs-share
```

To mount the NFS filesystem after a reboot
```
echo "util-01.mgmt:/data/nfs-share /data/nfs-share nfs4 defaults 1 1" >> /etc/fstab
```

### YUM update

add ```enabled=0``` under ```[base]```, ```[updates]``` and ```[extras]``` in CentOS-Base.repo

Scp the file 
```
scp devops@util-01.mgmt:/srv/salt/yum/local.repo /etc/yum.repos.d/
```

Create the /etc/yum.repos.d/local.repo 
```
[local-base]
name=CentOS-$releasever - Base
baseurl=file:///data/nfs-share/repo/centos/$releasever/$basearch/base
gpgcheck=0
enabled=1

[local-updates]
name=CentOS-$releasever - Updates
baseurl=file:///data/nfs-share/repo/centos/$releasever/$basearch/updates
gpgcheck=0
enabled=1

[local-extras]
name=CentOS-$releasever - Extras
baseurl=file:///data/nfs-share/repo/centos/$releasever/$basearch/extras
gpgcheck=0
enabled=1

[local-epel]
name=CentOS-$releasever - EPEL
baseurl=file:///data/nfs-share/repo/centos/$releasever/$basearch/epel
gpgcheck=0
enabled=1

[local-openstack-icehouse]
name=CentOS-$releasever - OpenStack Icehouse
baseurl=file:///data/nfs-share/repo/centos/$releasever/$basearch/openstack-icehouse
gpgcheck=0
enabled=1
priority=98
```

Clean out the YUM history and tell YUM to use the new repository
```
yum clean all
yum update
```
There should now be packages available for updating.
Reboot the system 
```
reboot now
```

## Install Salt Minion
```
yum install salt-minion
```
Start the service and set the minion to start after reboot
```
service salt-minion start
chkconfig salt-minion on
``` 

