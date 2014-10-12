# Glance - Image Service
Installing the glance service

[dl]: http://docs.openstack.org/icehouse/install-guide/install/yum/content/glance-install.html

### Install the Image Service on the controller node:
```
yum install openstack-glance python-glanceclient
echo $CONTROLLER
```

### Configure the Image Service on the controller node:
The Image Service stores information about images in a database.

```
echo $GLANCE_DBPASS
openstack-config --set /etc/glance/glance-api.conf database connection mysql://glance:$GLANCE_DBPASS@$CONTROLLER/glance
openstack-config --set /etc/glance/glance-registry.conf database connection mysql://glance:$GLANCE_DBPASS@$CONTROLLER/glance
```

### Configure the Image Service to use the message broker:

```    
openstack-config --set /etc/glance/glance-api.conf DEFAULT rpc_backend qpid
openstack-config --set /etc/glance/glance-api.conf DEFAULT qpid_hostname $CONTROLLER
```

### Use the password you created to log in as root and create a glance database user:

```
echo "DROP DATABASE IF EXISTS glance;" > glance.sql
echo "CREATE DATABASE glance;" >> glance.sql
echo "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';" >> glance.sql
echo "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';" >> glance.sql
echo "FLUSH PRIVILEGES;" >> glance.sql
mysql -u root -pmysql < glance.sql
```

### Create the database tables for the Image Service:

```
su -s /bin/sh -c "glance-manage db_sync" glance
```

### Create a glance user
Create a glance user that the Image Service can use to authenticate with the Identity service. Choose a password and specify an email address for the glance user. Use the service tenant and give the user the admin role:

```
export GLANCE_USER_EMAIL=devops@util-01.mgmt
echo $GLANCE_USER_EMAIL
keystone user-create --name=glance --pass=$GLANCE_PASS --email=$GLANCE_USER_EMAIL
keystone user-role-add --user=glance --tenant=service --role=admin
```

### Configure the Image Service to use the Identity Service for authentication.

```
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$CONTROLLER:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_host $CONTROLLER
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_user glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_password $GLANCE_PASS
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$CONTROLLER:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_host $CONTROLLER
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_user glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_password $GLANCE_PASS
openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone
```

### Register the Image Service
Register the Image Service with the Identity service so that other OpenStack services can locate it. Register the service and create the endpoint:

```
keystone service-create --name=glance --type=image --description="OpenStack Image Service"
keystone endpoint-create \
    --service-id=$(keystone service-list | awk '/ image / {print $2}') \
    --publicurl=http://$CONTROLLER:9292 \
    --internalurl=http://$CONTROLLER:9292 \
    --adminurl=http://$CONTROLLER:9292
```

### Start the glance-api and glance-registry services and configure them to start when the system boots:

```
service openstack-glance-api restart
service openstack-glance-registry restart
chkconfig openstack-glance-api on
chkconfig openstack-glance-registry on
```

### Verify Glance (Image) Service Installation

```
mkdir /tmp/images
cd /tmp/images/
wget http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img

file cirros-0.3.2-x86_64-disk.img
source /home/devops/openstack/admin-openrc.sh

glance image-create --name "cirros-0.3.2-x86_64" --disk-format qcow2 \
  --container-format bare --is-public True --progress < cirros-0.3.2-x86_64-disk.img
```

Confirm the image is available
```
glance image-list
```

### Next: Compute
