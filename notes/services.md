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
```

