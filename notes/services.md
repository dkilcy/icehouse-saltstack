# Services

Common
```
service salt-minion status
service iptables status

service qpidd status
```

Controller
```
service mysqld status

service neutron-server status
service openstack-keystone status
service openstack-glance-api status
service openstack-glance-registry status
service openstack-nova-api status
service openstack-nova-cert status
service openstack-nova-consoleauth status
service openstack-nova-scheduler status
service openstack-nova-novncproxy status
service openstack-nova-conductor status

service neutron-server restart
service openstack-keystone restart
service openstack-glance-api restart
service openstack-glance-registry restart
service openstack-nova-api restart
service openstack-nova-cert restart
service openstack-nova-consoleauth restart
service openstack-nova-scheduler restart
service openstack-nova-novncproxy restart
service openstack-nova-conductor restart


salt 'controller-01.mgmt' service.restart neutron-server

salt 'controller-01.mgmt' service.restart openstack-keystone

salt 'controller-01.mgmt' service.restart openstack-glance-api
salt 'controller-01.mgmt' service.restart openstack-glance-registry

salt 'controller-01.mgmt' service.restart openstack-nova-api
salt 'controller-01.mgmt' service.restart openstack-nova-cert
salt 'controller-01.mgmt' service.restart openstack-nova-consoleauth
salt 'controller-01.mgmt' service.restart openstack-nova-scheduler
salt 'controller-01.mgmt' service.restart openstack-nova-novncproxy
salt 'controller-01.mgmt' service.restart openstack-nova-conductor

```

Network
```
service neutron-server status
service neutron-openvswitch-agent status
service neutron-l3-agent status
service neutron-dhcp-agent status
service neutron-metadata-agent status
service openvswitch status

service neutron-server restart
service neutron-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service openvswitch restart

salt 'network-01.mgmt' service.restart neutron-server
salt 'network-01.mgmt' service.restart neutron-openvswitch-agent
salt 'network-01.mgmt' service.restart neutron-l3-agent
salt 'network-01.mgmt' service.restart neutron-dhcp-agent
salt 'network-01.mgmt' service.restart neutron-metadata-agent
salt 'network-01.mgmt' service.restart openvswitch

```
Compute
```
service libvirtd status
service neutron-server status
service neutron-openvswitch-agent status
service neutron-l3-agent status
service neutron-dhcp-agent status
service neutron-metadata-agent status
service openvswitch status
service openstack-nova-compute status

service libvirtd restart
service neutron-server restart
service neutron-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service openvswitch restart
service openstack-nova-compute restart

salt 'compute-01.mgmt' service.restart libvirtd
salt 'compute-01.mgmt' service.restart neutron-server
salt 'compute-01.mgmt' service.restart neutron-openvswitch-agent
salt 'compute-01.mgmt' service.restart neutron-l3-agent
salt 'compute-01.mgmt' service.restart neutron-dhcp-agent
salt 'compute-01.mgmt' service.restart neutron-metadata-agent
salt 'compute-01.mgmt' service.restart openvswitch
salt 'compute-01.mgmt' service.restart openstack-nova-compute
```


# Logs and /etc files

Controller
```
/var/log/mysqld.log

/var/log/glance/api.log
/var/log/glance/registry.log

/var/log/keystone/keystone.log
/var/log/keystone/keystone-startup.log

/var/log/neutron/server.log

/var/log/nova/api.log
/var/log/nova/cert.log
/var/log/nova/conductor.log
/var/log/nova/consoleauth.log
/var/log/nova/nova-manage.log
/var/log/nova/scheduler.log

/etc/glance/
/etc/keystone/
/etc/nova/
/etc/neutron/
```

Network
```
/var/log/neutron/dhcp-agent.log
/var/log/neutron/metadata-agent.log
/var/log/neutron/openvswitch-agent.log
/var/log/neutron/l3-agent.log
/var/log/neutron/neutron-ns-metadata-proxy-29cffd5c-1f45-410a-b90c-25741669dab0.log

```

Compute
```
/var/log/libvirtd/libvirtd.log
/var/log/libvirtd/lxc/
/var/log/libvirtd/qemu/
/var/log/libvirtd/uml/
/var/log/neutron/openvswitch-agent.log
/var/log/nova/compute.log
/var/log/openvswitch/ovsdb-server.log
/var/log/openvswitch/ovs-vswitchd.log

/etc/nova/
/etc/neutron/
/etc/openvswitch/

```



