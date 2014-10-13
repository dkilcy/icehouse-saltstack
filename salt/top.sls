
base:
  '*':
    - vim
    - ipv6/disable
    - iptables/stop
#    - uptodate

  'roles:workstation':
    - match: grain
    - apache
    - git
    - python
    - oracle-java
    - mysql.client
    - mysql.python
    - reposync
    - openstack
    - openstack.client
    - openstack.rc

  'roles:openstack_controller':
    - match: grain
    - users
    - ntp
    - qpid
    - mysql.client
    - mysql.server
    - mysql.python
    - openstack
    - openstack.keystone
    - openstack.glance
    - openstack.nova_service
    - openstack.neutron_controller
    - openstack.horizon

  'roles:openstack_network':
    - match: grain
    - users
    - ntp
    - mysql.python
    - openstack
    - openstack.neutron_network

  'roles:openstack_compute':
    - match: grain
    - users
    - ntp
    - mysql.python
    - openstack
    - openstack.nova_compute
    - openstack.neutron_compute

