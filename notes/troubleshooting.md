# Troubleshooting

- Make sure all the clocks are in sync on all the nodes:  `ntpq -p`
- Make sure qpidd is running on the controller nodes:  `service qpidd status`
- MySQL is running and responsive.  


1. Run on the controller node as root:

```
    nova-manage service list 
    
    [root@controller-01 ~]$ nova-manage service list
    Binary           Host                                 Zone             Status     State Updated_At
    nova-conductor   controller-01.mgmt                   internal         enabled    :-)   2014-10-12 17:03:32
    nova-scheduler   controller-01.mgmt                   internal         enabled    :-)   2014-10-12 17:03:32
    nova-consoleauth controller-01.mgmt                   internal         enabled    :-)   2014-10-12 17:03:32
    nova-cert        controller-01.mgmt                   internal         enabled    :-)   2014-10-12 17:03:32
    nova-compute     compute-01.mgmt                      nova             enabled    :-)   2014-10-12 17:03:39
    nova-compute     compute-02.mgmt                      nova             enabled    :-)   2014-10-12 17:03:38
```

2. 

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

#### References

- [Troubleshooting in OpenStack Cloud Computing][1]

[1]: https://www.packtpub.com/books/content/troubleshooting-openstack-cloud-computing




