###
# Configure a compute node
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/nova-compute.html
# Icehouse
# Author: David Kilcy
###

{% from "mysql/map.jinja" import mysql with context %}

{% set mysql_host = salt['pillar.get']('openstack:controller') %}
{% set controller = salt['pillar.get']('openstack:controller') %}
{% set admin_token = salt['pillar.get']('openstack:ADMIN_TOKEN') %}
{% set mysql_root_password = salt['pillar.get']('mysql:server:root_password', salt['grains.get']('server_id')) %}

{% set nova_dbpass = salt['pillar.get']('openstack:NOVA_DBPASS') %}
{% set nova_pass = salt['pillar.get']('openstack:NOVA_PASS') %}

{% set ip_addr = salt['network.interfaces']()['eth0']['inet'][0]['address'] %}

###
# Configure a compute node
#
# After you configure the Compute service on the controller node, you must configure another system as a compute node.
# The compute node receives requests from the controller node and hosts virtual machine instances.
###

###
# 1. Install the Compute packages:
###

openstack_nova_compute:
  pkg.installed:
    - name: openstack-nova-compute

###
# 2. Edit the /etc/nova/nova.conf configuration file:
###

nova_compute_conf_1:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: database
    - parameter: connection
    - value: mysql://nova:{{ nova_dbpass }}@{{ mysql_host }}/nova

nova_compute_conf_2:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: auth_strategy
    - value: keystone

nova_compute_conf_3:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: auth_uri
    - value: http://{{ controller }}:5000

nova_compute_conf_4:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: auth_host
    - value: {{ controller }}

nova_compute_conf_5:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: auth_protocol
    - value: http

nova_compute_conf_6:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: auth_port
    - value: '35357'

nova_compute_conf_7:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: admin_user
    - value: nova

nova_compute_conf_8:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: admin_tenant_name
    - value: service

nova_compute_conf_9:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: admin_password
    - value: {{ nova_pass }}

###
# 3. Configure the Compute service to use the Qpid message broker by setting these configuration keys:
###

nova_compute_conf_10:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: rpc_backend
    - value: qpid

nova_compute_conf_11:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: qpid_hostname
    - value: {{ controller }}

###
# 4. Configure Compute to provide remote console access to instances.
###

nova_compute_conf_12:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: my_ip
    - value: {{ ip_addr }} 

nova_compute_conf_13:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: vnc_enabled
    - value: 'True'

nova_compute_conf_14:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: vncserver_listen
    - value: 0.0.0.0

nova_compute_conf_15:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: vncserver_proxyclient_address
    - value: {{ ip_addr }}

nova_compute_conf_16:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: novncproxy_base_url
    - value: http://{{ controller }}:6080/vnc_auto.html

###
# 5. Specify the host that runs the Image Service.
###

nova_compute_conf_17:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: glance_host
    - value: {{ controller }}

###
# 6. Determine whether your system's processor and/or hypervisor support hardware acceleration for virtual machines.
###

# egrep -c '(vmx|svm)' /proc/cpuinfo
# openstack-config --set /etc/nova/nova.conf libvirt virt_type qemu

###
# 7. Start the Compute service and its dependencies. Configure them to start automatically when the system boots.
###

nova_libvirtd_service:
  service.running:
    - name: libvirtd
    - enable: True

nova_messagebus_service:
  service.running:
    - name: messagebus
    - enable: True

nova_compute_service:
  service.running:
    - name: openstack-nova-compute
    - enable: True

###

nova_libvirtd_enabled_on_boot:
  service.enabled:
    - name: libvirtd

nova_messagebus_enabled_on_boot:
  service.enabled:
    - name: messagebus

nova_compute_enabled_on_boot:
  service.enabled:
    - name: openstack-nova-compute

