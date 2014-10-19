# Kickstart file for controller-01

#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
logging --level=info
install
text
lang en_US
keyboard us

network --onboot yes --device eth0 --bootproto static --ip=10.0.0.11 --netmask 255.255.255.0 
network --onboot yes --device eth1 --bootproto static --ip=192.168.1.11 --netmask 255.255.255.0

rootpw --iscrypted $1$wMcywtdb$LBktYhg.JmHsm2gOf7OaT/
firewall --disabled
auth  --useshadow  --passalgo=sha512
selinux --disabled
timezone  America/New_York
bootloader --location=mbr

# Partition clearing information
clearpart --all  
autopart

#repo --name=base    --baseurl=http://10.0.0.6/yumrepo/centos/6/x86_64/base
#repo --name=epel    --baseurl=http://10.0.0.6/yumrepo/centos/6/x86_64/epel
#repo --name=extras  --baseurl=http://10.0.0.6/yumrepo/centos/6/x86_64/extras
#repo --name=updates --baseurl=http://10.0.0.6/yumrepo/centos/6/x86_64/updates

poweroff

%post
/usr/sbin/dmidecode -s 'baseboard-serial-number' >> /root/post.out d2>&1
/usr/bin/curl >> /root/post.out 2>&1
/usr/bin/python --version >> /root/post.out 2>&1

sed -i 's/NM_CONTROLLED=.*/NM_CONTROLLED=no/g' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/NM_CONTROLLED=.*/NM_CONTROLLED=no/g' /etc/sysconfig/network-scripts/ifcfg-eth1
#sed -i 's/NM_CONTROLLED=.*/NM_CONTROLLED=no/g' /etc/sysconfig/network-scripts/ifcfg-eth2

# Replace /etc/resolv.conf
echo "
search mgmt
nameserver 192.168.1.1
" > /etc/resolv.conf

# Replace /etc/sysconfig/network
echo "
NETWORKING=yes
HOSTNAME=controller-01.mgmt
GATEWAY=192.168.1.1
" > /etc/sysconfig/network

echo "
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
  
###############################################################################
# Network:
# *.mgmt    - OpenStack Internal Network
# *.pub     - Public Network
# *.vm      - VM Traffic Network
###############################################################################

10.0.0.5        workstation-01.mgmt workstation-01
10.0.0.6        workstation-02.mgmt workstation-02 salt ntp yumrepo 
10.0.0.7        workstation-03.mgmt workstation-03

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
  
192.168.1.5     workstation-01.pub
192.168.1.6     workstation-02.pub
192.168.1.7     workstation-03.pub  

192.168.1.11    controller-01.pub
192.168.1.12    controller-02.pub
" > /etc/hosts

yum -y remove yum-plugin-fastestmirror >> /root/yum.out 2>&1
rm -f /etc/yum.repos.d/*
ls -l /etc/yum.repos.d/ >> /root/yum.out 2>&1

echo "
[base]
name=CentOS-$releasever - Base
baseurl=http://yumrepo/yumrepo/centos/6/x86_64/base/
gpgcheck=0
enabled=1

[updates]
name=CentOS-$releasever - Updates
baseurl=http://yumrepo/yumrepo/centos/6/x86_64/updates/
gpgcheck=0
enabled=1

[extras]
name=CentOS-$releasever - Extras
baseurl=http://yumrepo/yumrepo/centos/6/x86_64/extras/
gpgcheck=0
enabled=1

[epel]
name=Extra Packages for Enterprise Linux 6 - $basearch
baseurl=http://yumrepo/yumrepo/centos/6/x86_64/epel
gpgcheck=0
enabled=1

[openstack-icehouse]
name=OpenStack Icehouse Repository
baseurl=http://yumrepo/yumrepo/centos/6/x86_64/openstack-icehouse
gpgcheck=0
enabled=1
" > /etc/yum.repos.d/yumrepo-centos.repo

echo "
[main]
enabled=0
" > /etc/yum/pluginconf.d/fastestmirror.conf

yum -y clean all >> /root/yum.out 2>&1
yum -y update >> /root/yum.out 2>&1

rm -f /etc/yum.repos.d/Cent*
echo "
[main]
enabled=0
" > /etc/yum/pluginconf.d/fastestmirror.conf

yum -y clean all >> /root/yum.out 2>&1
yum -y update >> /root/yum.out 2>&1

yum -y install salt-minion >> /root/yum.out 2>&1
sed -i "s/#id:/id: controller-01/" /etc/salt/minion
chkconfig salt-minion on
service salt-minion restart

%end

%packages
@additional-devel
@base
@compat-libraries
@console-internet
@debugging
@hardware-monitoring
@large-systems
@legacy-unix
@mysql-client
@network-file-system-client
@network-tools
@performance
@security-tools
@server-platform
@system-admin-tools
@system-management-snmp
crypto-utils
hmaccalc
net-snmp-python
python-dmidecode
-kexec-tools
-NetworkManager

%end
