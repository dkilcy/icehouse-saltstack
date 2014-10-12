##
# Configure network node
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/neutron-ml2-controller-node.html
# Icehouse
# Author: David Kilcy
###

{% from "mysql/map.jinja" import mysql with context %}

{% set mysql_host = salt['pillar.get']('openstack:controller') %}
{% set controller = salt['pillar.get']('openstack:controller') %}
{% set admin_token = salt['pillar.get']('openstack:ADMIN_TOKEN') %}
{% set mysql_root_password = salt['pillar.get']('mysql:server:root_password', salt['grains.get']('server_id')) %}

{% set neutron_pass = salt['pillar.get']('openstack:NEUTRON_PASS') %}
{% set neutron_dbpass = salt['pillar.get']('openstack:NEUTRON_DBPASS') %}
{% set metadata_secret = salt['pillar.get']('openstack:METADATA_SECRET') %}

{% set instance_tunnels_interface_ip_address = salt['network.interfaces']()['eth2']['inet'][0]['address'] %}

###
# Prerequesites
###

###
# Edit kernel configuration
###

net.ipv4.conf.default.rp_filter:
  sysctl.present:
    - value: 0

net.ipv4.conf.all.rp_filter:
  sysctl.present:
    - value: 0

net.ipv4.ip_forward:
  sysctl.present:
    - value: 1

load_sysctl_openstack_neutron:
  cmd.run:
    - name: sysctl -q

###
# Install the Networking components
###

openstack_neutron:
  pkg.installed:
    - name: openstack-neutron

openstack_neutron_ml2:
  pkg.installed:
    - name: openstack-neutron-ml2

openstack_neutron_openvswitch:
  pkg.installed:
    - name: openstack-neutron-openvswitch

###
# Configure the Networking common components
###

###
# 1. Configure Networking to use the Identity service for authentication:
###

neturon_network_conf_2:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: auth_strategy
    - value: keystone

neturon_network_conf_3:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_uri
    - value: http://{{ controller }}:5000

neturon_network_conf_4:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_host
    - value: {{ controller }}

neturon_network_conf_5:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_port
    - value: '35357'

neturon_network_conf_6:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_protocol
    - value: http

neturon_network_conf_7:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: admin_tenant_name
    - value: service

neturon_network_conf_8:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: admin_user
    - value: neutron

neturon_network_conf_9:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: admin_password
    - value: {{ neutron_pass }}

###
# 2. Configure Networking to use the message broker:
###

neturon_network_conf_10:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: rpc_backend
    - value: neutron.openstack.common.rpc.impl_qpid

neturon_network_conf_11:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: qpid_hostname
    - value: {{ controller }}

###
# 3. Configure Networking to use the ML2 plugin-and associated services:
###

neturon_network_conf_12:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: core_plugin
    - value: ml2

neturon_network_conf_13:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: service_plugins
    - value: router

###
# Configure the Layer-3 (L3) agent
###

neturon_network_conf_14:
  openstack_config.present:
    - filename: /etc/neutron/l3_agent.ini
    - section: DEFAULT
    - parameter: interface_driver
    - value: neutron.agent.linux.interface.OVSInterfaceDriver

neturon_network_conf_15:
  openstack_config.present:
    - filename: /etc/neutron/l3_agent.ini
    - section: DEFAULT
    - parameter: use_namespaces
    - value: 'True'

###
# Configure the DHCP agent
###

neturon_network_conf_16:
  openstack_config.present:
    - filename: /etc/neutron/dhcp_agent.ini
    - section: DEFAULT
    - parameter: interface_driver
    - value: neutron.agent.linux.interface.OVSInterfaceDriver

neturon_network_conf_17:
  openstack_config.present:
    - filename: /etc/neutron/dhcp_agent.ini
    - section: DEFAULT
    - parameter: dhcp_driver
    - value: neutron.agent.linux.dhcp.Dnsmasq

neturon_network_conf_18:
  openstack_config.present:
    - filename: /etc/neutron/dhcp_agent.ini
    - section: DEFAULT
    - parameter: use_namespaces
    - value: 'True'


###
# Configure the metadata agent
###

neutron_metadata_agent_1:
  openstack_config.present:
    - filename: /etc/neutron/metadata_agent.ini
    - section: DEFAULT
    - parameter: auth_url
    - value: http://{{ controller }}:5000/v2.0

neutron_metadata_agent_2:
  openstack_config.present:
    - filename: /etc/neutron/metadata_agent.ini
    - section: DEFAULT 
    - parameter: auth_region
    - value: regionOne

neutron_metadata_agent_3:
  openstack_config.present:
    - filename: /etc/neutron/metadata_agent.ini
    - section: DEFAULT
    - parameter: admin_tenant_name
    - value: service

neutron_metadata_agent_4:
  openstack_config.present:
    - filename: /etc/neutron/metadata_agent.ini
    - section: DEFAULT
    - parameter: admin_user
    - value: neutron

neutron_metadata_agent_5:
  openstack_config.present:
    - filename: /etc/neutron/metadata_agent.ini
    - section: DEFAULT
    - parameter: admin_password
    - value: {{ neutron_pass }}

neutron_metadata_agent_6:
  openstack_config.present:
    - filename: /etc/neutron/metadata_agent.ini
    - section: DEFAULT
    - parameter: nova_metadata_ip
    - value: {{ controller }}

neutron_metadata_agent_7:
  openstack_config.present:
    - filename: /etc/neutron/metadata_agent.ini
    - section: DEFAULT
    - parameter: metadata_proxy_shared_secret
    - value: {{ metadata_secret }}

neutron_metadata_agent_8:
  openstack_config.present:
    - filename: /etc/neutron/metadata_agent.ini
    - section: DEFAULT
    - parameter: verbose
    - value: 'True'

###
# configure the Modular Layer 2 (ML2) plug-in and associated services
###

neutron_ml2_plugin_1:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2
    - parameter: type_drivers
    - value: gre

neutron_ml2_plugin_2:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2
    - parameter: tenant_network_types
    - value: gre

neutron_ml2_plugin_3:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2
    - parameter: mechanism_drivers
    - value: openvswitch

neutron_ml2_plugin_4:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2_type_gre
    - parameter: tunnel_id_ranges
    - value: '1:1000'

neutron_ml2_plugin_5:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ovs
    - parameter: local_ip
    - value: {{ instance_tunnels_interface_ip_address }}

neutron_ml2_plugin_:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ovs
    - parameter: tunnel_type
    - value: gre

neutron_ml2_plugin_6:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ovs
    - parameter: enable_tunneling
    - value: 'True'

neutron_ml2_plugin_7:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: securitygroup
    - parameter: firewall_driver
    - value: neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

neutron_ml2_plugin_8:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: securitygroup
    - parameter: enable_security_group
    - value: 'True'

###
# Configure the Open vSwitch (OVS) service
###

###
# 1. Start the OVS service and configure it to start when the system boots:
###

openvswitch_service_start:
  service.running:
    - name: openvswitch

openvswitch_servce_enabled_on_boot:
  service.enabled:
    - name: openvswitch

###
# 2. Add the integration bridge:
###

openvswitch_add_integration_bridge:
  cmd.run:
    - name: ovs-vsctl add-br br-int

###
# 3. Add the external bridge:
###

openvswitch_add_external_bridge:
  cmd.run:
    - name: ovs-vsctl add-br br-ex

###
# 4. Add a port to the external bridge that connects to the physical external network interface:
###

openvswitch_add_external_bridge_to_external_nic:
  cmd.run:
    - name: ovs-vsctl add-port br-ex eth2

###
# Finalize the installation
###

###
# 1. The Networking service initialization scripts expect a symbolic link /etc/neutron/plugin.ini
#  pointing to the configuration file associated with your chosen plug-in. Using the ML2 plug-in,
#  for example, the symbolic link must point to /etc/neutron/plugins/ml2/ml2_conf.ini.
#  If this symbolic link does not exist, create it using the following commands:
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

neutron_copy_neutron_openvswitch_agent:
  file.copy:
    - name: /etc/init.d/neutron-openvswitch-agent.orig
    - source: /etc/init.d/neutron-openvswitch-agent
    - preserve: True

neutron_replace_neutron_openvswitch_agent:
  file.replace:
    - name: /etc/init.d/neutron-openvswitch-agent
    - path: /etc/init.d/neutron-openvswitch-agent
    - pattern: plugins/openvswitch/ovs_neutron_plugin.ini
    - repl: plugin.ini

###
# 2. Start the Networking services and configure them to start when the system boots:
###

compute_openvswitch_agent_service_start:
  service.running:
    - name: neutron-openvswitch-agent

compute_openvswitch_agent_service_enabled_on_boot:
  service.enabled:
    - name: neutron-openvswitch-agent

compute_l3_agent_service_start:
  service.running:
    - name: neutron-l3-agent

compute_l3_agent_service_enabled_on_boot:
  service.enabled:
    - name: neutron-l3-agent

compute_dhcp_agent_service_start:
  service.running:
    - name: neutron-dhcp-agent

compute_dhcp_agent_service_enabled_on_boot:
  service.enabled:
    - name: neutron-dhcp-agent

compute_metadata_agent_service_start:
  service.running:
    - name: neutron-metadata-agent

compute_metadata_agent_service_enabled_on_boot:
  service.enabled:
    - name: neutron-metadata-agent

