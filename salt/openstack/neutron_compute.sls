###
# Configure compute node
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/neutron-ml2-compute-node.html
# Icehouse
# author: David Kilcy
###

{% from "mysql/map.jinja" import mysql with context %}

{% set mysql_host = salt['pillar.get']('openstack:controller') %}
{% set controller = salt['pillar.get']('openstack:controller') %}
{% set admin_token = salt['pillar.get']('openstack:ADMIN_TOKEN') %}
{% set mysql_root_password = salt['pillar.get']('mysql:server:root_password', salt['grains.get']('server_id')) %}

{% set neutron_pass = salt['pillar.get']('openstack:NEUTRON_PASS') %}
{% set neutron_dbpass = salt['pillar.get']('openstack:NEUTRON_DBPASS') %}
{% set nova_pass = salt['pillar.get']('openstack:NOVA_PASS') %}
{% set metadata_secret = salt['pillar.get']('openstack:METADATA_SECRET') %}

{% set instance_tunnels_interface_ip_address = salt['network.interfaces']()['eth2']['inet'][0]['address'] %}

###
# Prerequisites
###

###
# 1. Edit kernel configuration
###

net.ipv4.conf.default.rp_filter:
  sysctl.present:
    - value: 0

net.ipv4.conf.all.rp_filter:
  sysctl.present:
    - value: 0

###
# 2. Implement the changes
###

load_sysctl_openstack_compute:
  cmd.run:
    - name: sysctl -q

###
# Install networking components
###

openstack_neutron_compute_ml2:
  pkg.installed:
    - name: openstack-neutron-ml2

openstack_neutron_compute_openvswitch:
  pkg.installed:
    - name: openstack-neutron-openvswitch

###
# Configure networking common components
###

###
# 1. Configure Networking to use the Identity service for authenticatio
###

compute_network_conf_2:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: auth_strategy
    - value: keystone

compute_network_conf_3:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_uri
    - value: http://{{ controller }}:5000

compute_network_conf_4:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_host
    - value: {{ controller }}

compute_network_conf_5:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_port
    - value: '35357'

compute_network_conf_6:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_protocol
    - value: http

compute_network_conf_7:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: admin_tenant_name
    - value: service

compute_network_conf_8:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: admin_user
    - value: neutron

compute_network_conf_9:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: admin_password
    - value: {{ neutron_pass }}

###
# 2. Configure Networking to use the message broker:
###

compute_network_conf_10:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: rpc_backend
    - value: neutron.openstack.common.rpc.impl_qpid

compute_network_conf_11:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: qpid_hostname
    - value: {{ controller }}

###
# 3. Configure Networking to use the Modular Layer 2 (ML2) plug-in and associated services:
###

compute_network_conf_12:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: core_plugin
    - value: ml2

compute_network_conf_13:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: service_plugins
    - value: router

###
# configure the Modular Layer 2 (ML2) plug-in
###

compute_ml2_plugin_1:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2
    - parameter: type_drivers
    - value: gre

compute_ml2_plugin_2:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2
    - parameter: tenant_network_types
    - value: gre

compute_ml2_plugin_3:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2
    - parameter: mechanism_drivers
    - value: openvswitch

compute_ml2_plugin_4:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2_type_gre
    - parameter: tunnel_id_ranges
    - value: '1:1000'

compute_ml2_plugin_5:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ovs
    - parameter: local_ip
    - value: {{ instance_tunnels_interface_ip_address }}

compute_ml2_plugin_:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ovs
    - parameter: tunnel_type
    - value: gre

compute_ml2_plugin_6:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ovs
    - parameter: enable_tunneling
    - value: 'True'

compute_ml2_plugin_7:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: securitygroup
    - parameter: firewall_driver
    - value: neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

compute_ml2_plugin_8:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: securitygroup
    - parameter: enable_security_group
    - value: 'True'

###
# To configure the Open vSwitch (OVS) service
###

###
# 1. Start the OVS service and configure it to start when the system boots:
###

compute_openvswitch_service_start:
  service.running:
    - name: openvswitch

compute_openvswitch_service_enabled_on_boot:
  service.enabled:
    - name: openvswitch

###
# 2. Add the integration bridge:
###

compute_openvswitch_add_integration_bridge:
  cmd.run:
    - name: ovs-vsctl add-br br-int

###
# To configure Compute to use Networking
###

compute_controller_conf_27:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: network_api_class
    - value: nova.network.neutronv2.api.API

compute_controller_conf_28:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_url
    - value: http://{{ controller }}:9696

compute_controller_conf_29:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_auth_strategy
    - value: keystone

compute_controller_conf_30:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_admin_tenant_name
    - value: service

compute_controller_conf_31:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_admin_username
    - value: neutron

compute_controller_conf_32:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_admin_password
    - value: {{ neutron_pass }}

compute_controller_conf_33:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_admin_auth_url
    - value: http://{{ controller }}:35357/v2.0

compute_controller_conf_34:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: linuxnet_interface_driver
    - value: nova.network.linux_net.LinuxOVSInterfaceDriver

compute_controller_conf_35:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: firewall_driver
    - value: nova.virt.firewall.NoopFirewallDriver

compute_controller_conf_36:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: security_group_api
    - value: neutron

###
# Finalize the installation
###

###
# 1. The Networking service initialization scripts expect a symbolic link /etc/neutron/plugin.ini
#  pointing to the configuration file associated with your chosen plug-in. Using the ML2 plug-in, 
#  for example, the symbolic link must point to /etc/neutron/plugins/ml2/ml2_conf.ini. If this 
#  symbolic link does not exist, create it using the following commands:
###

/etc/neutron/plugin.ini:
  file.symlink:
    - name: /etc/neutron/plugin.ini
    - target: /etc/neutron/plugins/ml2/ml2_conf.ini

###
# Due to a packaging bug, the Open vSwitch agent initialization script explicitly looks for the 
# Open vSwitch plug-in configuration file rather than a symbolic link /etc/neutron/plugin.ini 
# pointing to the ML2 plug-in configuration file. Run the following commands to resolve this issue:
###

compute_copy_neutron_openvswitch_agent:
  file.copy:
    - name: /etc/init.d/neutron-openvswitch-agent.orig
    - source: /etc/init.d/neutron-openvswitch-agent
    - preserve: True

# sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /etc/init.d/neutron-openvswitch-agent
compute_replace_neutron_openvswitch_agent:
  file.replace:
    - name: /etc/init.d/neutron-openvswitch-agent
    - path: /etc/init.d/neutron-openvswitch-agent
    - pattern: plugins/openvswitch/ovs_neutron_plugin.ini
    - repl: plugin.ini

###
# 2. Restart the Compute service:
###

compute_nova_compute_restart:
  service.restart:
    - name: openstack-nova-compute

###
# 3. Start the Open vSwitch (OVS) agent and configure it to start when the system boots:
###

compute_openvswitch_agent_service_start:
  service.running:
    - name: neutron-openvswitch-agent

compute_openvswitch_agent_service_enabled_on_boot:
  service.enabled:
    - name: neutron-openvswitch-agent


