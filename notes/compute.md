# Nova - Compute Service

[dl]: http://docs.openstack.org/icehouse/install-guide/install/yum/content/ch_nova.html
[dl]: http://docs.openstack.org/icehouse/install-guide/install/yum/content/nova-controller.html

### Install compute services on the controller node

```
export CONTROLLER=controller-01
export CONTROLLER_IP=10.0.0.11

export NOVA_USER_EMAIL=devops@util-01.mgmt

echo $CONTROLLER
echo $CONTROLLER_IP
echo $NOVA_DBPASS
echo $NOVA_PASS
echo $NOVA_USER_EMAIL

yum install openstack-nova-api openstack-nova-cert openstack-nova-conductor \
    openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler \
    python-novaclient
```

#### Configure Compute with the database location and credentials
``` 
openstack-config --set /etc/nova/nova.conf database connection mysql://nova:$NOVA_DBPASS@$CONTROLLER/nova
```

#### configure Compute to use the Qpid message broker
```
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend qpid
openstack-config --set /etc/nova/nova.conf DEFAULT qpid_hostname $CONTROLLER
```

#### Configure management interface
```
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $CONTROLLER_IP
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen $CONTROLLER_IP
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $CONTROLLER_IP
```

#### Create a nova database user and tables
```
echo "DROP DATABASE IF EXISTS nova;" > nova.sql
echo "CREATE DATABASE nova;" >> nova.sql
echo "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';" >> nova.sql
echo "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';" >> nova.sql
echo "FLUSH PRIVILEGES;" >> nova.sql
mysql -u root -pmysql < nova.sql

su -s /bin/sh -c "nova-manage db sync" nova
```

#### Create a nova user that Compute uses to authenticate with the Identity Service
```
keystone user-create --name=nova --pass=$NOVA_PASS --email=$NOVA_USER_EMAIL
keystone user-role-add --user=nova --tenant=service --role=admin
```

#### Configure Compute to use these credentials with the Identity Service running on the controller
```
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$CONTROLLER:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_host $CONTROLLER
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password $NOVA_PASS
```

#### register Compute with the Identity Service
```
keystone service-create --name=nova --type=compute --description="OpenStack Compute"

keystone endpoint-create \
  --service-id=$(keystone service-list | awk '/ compute / {print $2}') \
  --publicurl=http://$CONTROLLER:8774/v2/%\(tenant_id\)s \
  --internalurl=http://$CONTROLLER:8774/v2/%\(tenant_id\)s \
  --adminurl=http://$CONTROLLER:8774/v2/%\(tenant_id\)s
```

#### Start Compute services
```
service openstack-nova-api restart
service openstack-nova-cert restart
service openstack-nova-consoleauth restart
service openstack-nova-scheduler restart
service openstack-nova-conductor restart
service openstack-nova-novncproxy restart
chkconfig openstack-nova-api on
chkconfig openstack-nova-cert on
chkconfig openstack-nova-consoleauth on
chkconfig openstack-nova-scheduler on
chkconfig openstack-nova-conductor on
chkconfig openstack-nova-novncproxy on
```

Verify
```
nova image-list
```

# Configure the Compute node

#### Install Compute packages on compute node
```
source /home/devops/openstack/auth.sh
export CONTROLLER=controller-01
export COMPUTE_IP=10.0.0.31
```

#### Configure nova.conf
```
yum install openstack-nova-compute
 
openstack-config --set /etc/nova/nova.conf database connection mysql://nova:$NOVA_DBPASS@$CONTROLLER/nova
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$CONTROLLER:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_host $CONTROLLER
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password $NOVA_PASS

openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend qpid
openstack-config --set /etc/nova/nova.conf DEFAULT qpid_hostname $CONTROLLER

openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $COMPUTE_IP
openstack-config --set /etc/nova/nova.conf DEFAULT vnc_enabled True
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $COMPUTE_IP
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://$CONTROLLER:6080/vnc_auto.html

openstack-config --set /etc/nova/nova.conf DEFAULT glance_host $CONTROLLER

service libvirtd start
service messagebus start

chkconfig libvirtd on
chkconfig messagebus on

service openstack-nova-compute start

chkconfig openstack-nova-compute on
```

http://docs.openstack.org/icehouse/install-guide/install/yum/content/ch_networking.html
