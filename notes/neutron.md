
# Neutron - Network Service

[dl]: http://docs.openstack.org/icehouse/install-guide/install/yum/content/ch_networking.html


### Create the neutron database on the controller node
```
echo "DROP DATABASE IF EXISTS neutron;" > neutron.sql
echo "CREATE DATABASE neutron;" >> neutron.sql
echo "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';" >> neutron.sql
echo "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';" >> neutron.sql
echo "FLUSH PRIVILEGES;" >> neutron.sql

mysql -u root -pmysql < neutron.sql
```

### Create Identity service credentials for Networking:

```
export CONTROLLER=controller-01
export NEUTRON_USER_EMAIL=devops@util-01.mgmt

echo $CONTROLLER
echo $NEUTRON_PASS
echo $NEUTRON_USER_EMAIL

keystone user-create --name neutron --pass $NEUTRON_PASS --email $NEUTRON_USER_EMAIL
keystone user-role-add --user neutron --tenant service --role admin

keystone service-create --name neutron --type network --description "OpenStack Networking"
keystone endpoint-create \
  --service-id $(keystone service-list | awk '/ network / {print $2}') \
  --publicurl http://$CONTROLLER:9696 \
  --adminurl http://$CONTROLLER:9696 \
  --internalurl http://$CONTROLLER:9696
```

### Install software
```
yum install openstack-neutron openstack-neutron-ml2 python-neutronclient
```

### Configure networking to use the database
```
openstack-config --set /etc/neutron/neutron.conf database connection \
  mysql://neutron:$NEUTRON_DBPASS@$CONTROLLER/neutron
```

### Configure networking to use the identity service
```
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$CONTROLLER:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host $CONTROLLER
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password $NEUTRON_PASS
```

### Configure networking to use the message broker
```
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname $CONTROLLER
```

### Configure Networking to notify Compute about network topology changes:
```
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_url http://$CONTROLLER:8774/v2
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_username nova
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_tenant_id $(keystone tenant-list | awk '/ service / { print $2 }')
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_password $NOVA_PASS
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_auth_url http://$CONTROLLER:35357/v2.0
```

### Configure networking to use ML2
```
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
```

### Configure ML2
```
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
```

### Configure compute to use networking
```
openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://$CONTROLLER:9696
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_username neutron
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password $NEUTRON_PASS
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url http://$CONTROLLER:35357/v2.0
openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron
```

### Finalize
```
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

service openstack-nova-api restart
service openstack-nova-scheduler restart
service openstack-nova-conductor restart

service neutron-server start
chkconfig neutron-server on
```
  
# Configure Network node

### Turn on IP forwarding

From Salt master, execute
```
salt 'network-01.mgmt' openstack-proj/ip_forward
salt 'network-01.mgmt' openstack-proj/rp_filter
```

### Install networking components
```
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
```

### Configure networking components
```
source /home/devops/openstack/auth.sh
source /home/devops/openstack/admin-openrc.sh

export CONTROLLER=controller-01

echo $CONTROLLER
echo $NEUTRON_PASS

openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$CONTROLLER:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host $CONTROLLER
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password $NEUTRON_PASS
```

### Configure networking to use the message broker
```
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname $CONTROLLER
```

### Configure networking to use ML2
```
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
```

### Configure layer 3 agent
```
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT use_namespaces True
```

### Configure DHCP agent
```
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT use_namespaces True
```

### Configure metadata agent
```
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_url http://$CONTROLLER:5000/v2.0
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_region regionOne
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_tenant_name service
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_user neutron
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_password $NEUTRON_PASS
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $CONTROLLER
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $METADATA_SECRET
```
### On the **Controller** node
```
openstack-config --set /etc/nova/nova.conf DEFAULT service_neutron_metadata_proxy true
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_metadata_proxy_shared_secret $METADATA_SECRET
service openstack-nova-api restart
```
### Configure ML2 on the Network node
```
export INSTANCE_TUNNELS_INTERFACE_IP_ADDRESS=10.0.1.21

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip $INSTANCE_TUNNELS_INTERFACE_IP_ADDRESS
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs tunnel_type gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs enable_tunneling True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
```

### Configure Open vSwitch
```
service openvswitch start
chkconfig openvswitch on
```

```
export INTERFACE_NAME=eth1

ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $INTERFACE_NAME

## ethtool -K INTERFACE_NAME gro off
```

### Finalize
```
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

cp /etc/init.d/neutron-openvswitch-agent /etc/init.d/neutron-openvswitch-agent.orig
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /etc/init.d/neutron-openvswitch-agent

service neutron-openvswitch-agent start
service neutron-l3-agent start
service neutron-dhcp-agent start
service neutron-metadata-agent start
chkconfig neutron-openvswitch-agent on
chkconfig neutron-l3-agent on
chkconfig neutron-dhcp-agent on
chkconfig neutron-metadata-agent on
```

# Configure Compute node

On Salt master, execute
```
salt 'compute-01.mgmt' state.sls openstack-proj/rp_filter
```

### Install networking components
```
yum install openstack-neutron-ml2 openstack-neutron-openvswitch
```

### Configure networking components
```
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$CONTROLLER:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host $CONTROLLER
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password $NEUTRON_PASS
```

### Configure networking to use the message broker
```
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname $CONTROLLER
```

### Configure networking to use ML2
```
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
```

### Configure ML2
```
export INSTANCE_TUNNELS_INTERFACE_IP_ADDRESS=10.0.1.31

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip $INSTANCE_TUNNELS_INTERFACE_IP_ADDRESS
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs tunnel_type gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs enable_tunneling True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
```

### Configure Open vSwitch
```
service openvswitch start
chkconfig openvswitch on

ovs-vsctl add-br br-int
```

### Configure compute to use networking
```
openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://$CONTROLLER:9696
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_username neutron
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password $NEUTRON_PASS
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url http://$CONTROLLER:35357/v2.0
openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron
```

### Finalize
```
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

cp /etc/init.d/neutron-openvswitch-agent /etc/init.d/neutron-openvswitch-agent.orig
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /etc/init.d/neutron-openvswitch-agent

service openstack-nova-compute restart
service neutron-openvswitch-agent start
chkconfig neutron-openvswitch-agent on
```

# Create initial networks

[dl]: http://docs.openstack.org/icehouse/install-guide/install/yum/content/neutron_initial-external-network.html

**Perform these steps on the controller node**

### Create external network

```
source admin-openrc.sh 

neutron net-create ext-net --shared --router:external=True
neutron subnet-create ext-net --name ext-subnet \
 --allocation-pool start=192.168.1.152,end=192.168.1.200 \
 --disable-dhcp --gateway 192.168.1.1 192.168.1.0/24
```

### Tenant network
```
source /home/devops/openstack/demo-openrc.sh

neutron net-create demo-net
neutron subnet-create demo-net --name demo-subnet \
 --gateway 172.16.1.1 172.16.1.0/24

neutron net-list

neutron router-create demo-router
neutron router-interface-add demo-router demo-subnet
neutron router-gateway-set demo-router ext-net
```
### Verify connectivity
```
ping 172.16.1.1
```

### Next: Launch

## References
```
source admin-openrc.sh 

keystone role-list
keystone service-list
keystone tenant-list

neutron agent-list
neutron floatingip-list
neutron net-list
neutron router-list
neutron subnet-list

nova flavor-list
nova list
nova hypervisor-list
nova image-list
nova keypair-list
nova secgroup-list
```
