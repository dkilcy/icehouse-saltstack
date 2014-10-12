# Keystone - Identity Service

[dl]: http://docs.openstack.org/icehouse/install-guide/install/yum/content/keystone-install.html


### Configure MySQL on controller-01

```
mysql_secure_installation
```

### Install identity service

#### Install keystone identity service
```
cd ~

yum install openstack-keystone python-keystoneclient

export CONTROLLER=controller-01
echo $CONTROLLER
```

#### Specify the location of the database
```
echo $KEYSTONE_DBPASS

openstack-config --set /etc/keystone/keystone.conf database connection mysql://keystone:$KEYSTONE_DBPASS@$CONTROLLER/keystone
```

#### Create keystone database user and create the tables
```
echo "DROP DATABASE IF EXISTS keystone;" > keystone.sql
echo "CREATE DATABASE keystone;" >> keystone.sql
echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';" >> keystone.sql
echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';" >> keystone.sql
echo "FLUSH PRIVILEGES;" >> keystone.sql

mysql -u root -pmysql < keystone.sql

su -s /bin/sh -c "keystone-manage db_sync" keystone
```

#### Define the authorization token
```
echo $ADMIN_TOKEN
openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN
```

#### PKI Tokens
```
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /etc/keystone/ssl
chmod -R o-rwx /etc/keystone/ssl
```

#### Start the identity service
```
service openstack-keystone restart
chkconfig openstack-keystone on
```

### Define Users, Tenants and Roles
```
export OS_SERVICE_TOKEN=$ADMIN_TOKEN
export OS_SERVICE_ENDPOINT=http://$CONTROLLER:35357/v2.0
echo $OS_SERVICE_TOKEN
echo $OS_SERVICE_ENDPOINT

export ADMIN_EMAIL=devops@util-01.mgmt
echo $ADMIN_EMAIL

keystone user-create --name=admin --pass=$ADMIN_PASS --email=$ADMIN_EMAIL
keystone role-create --name=admin
keystone tenant-create --name=admin --description="Admin Tenant"
keystone user-role-add --user=admin --tenant=admin --role=admin
keystone user-role-add --user=admin --role=_member_ --tenant=admin

export DEMO_EMAIL=devops@util-01.mgmt
echo $DEMO_EMAIL

keystone user-create --name=demo --pass=$DEMO_PASS --email=$DEMO_EMAIL
keystone tenant-create --name=demo --description="Demo Tenant"
keystone user-role-add --user=demo --role=_member_ --tenant=demo
```

#### Create the Service Tenant
```
keystone tenant-create --name=service --description="Service Tenant"
```

#### Create Service entry for identity service
```
keystone service-create --name=keystone --type=identity --description="OpenStack Identity"
```

#### Specify an API endpoint for the Identity Service by using the returned service ID
```
keystone endpoint-create \
  --service-id=$(keystone service-list | awk '/ identity / {print $2}') \
  --publicurl=http://$CONTROLLER:5000/v2.0 \
  --internalurl=http://$CONTROLLER:5000/v2.0 \
  --adminurl=http://$CONTROLLER:35357/v2.0
```

### Verify the identity service installation
```
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT

keystone --os-username=admin --os-password=$ADMIN_PASS --os-auth-url=http://$CONTROLLER:35357/v2.0 token-get
keystone --os-username=admin --os-password=$ADMIN_PASS --os-tenant-name=admin --os-auth-url=http://$CONTROLLER:35357/v2.0 token-get
```

Create admin-openrc.sh
```
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://controller-01:35357/v2.0
```

#### Verify that your admin-openrc.sh file is configured correctly. Run the same command without the --os-* arguments
```
source admin-openrc.sh

keystone token-get
```

#### Verify that your admin account has authorization to perform administrative commands
```
keystone user-list
keystone user-role-list --user admin --tenant admin
```

###Next: clients.txt
