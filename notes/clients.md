# Install Clients

[dl]: http://docs.openstack.org/icehouse/install-guide/install/yum/content/ch_clients.html

```
yum install python-pip python-novaclient python-glanceclient python-neutronclient python-keystoneclient
```

create /home/devops/openstack/demo-openrc.sh
```
export OS_USERNAME=demo
export OS_PASSWORD=D$EMO_PASS
export OS_TENANT_NAME=demo
export OS_AUTH_URL=http://$CONTROLLER:35357/v2.0
```

###Next: glance.txt
