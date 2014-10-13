###
# Configure controller node
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
{% set nova_pass = salt['pillar.get']('openstack:NOVA_PASS') %}
{% set metadata_secret = salt['pillar.get']('openstack:METADATA_SECRET') %}

# TODO: figure out a better way to assign the nova_admin_tenant_id
{% set nova_admin_tenant_id = salt['pillar.get']('openstack:nova_admin_tenant_id') %}

###
# Prerequesites
###

###
# 1. Connect to the database as the root user, create the neutron database, and grant the proper access to it:
###

neutron_db:
  mysql_database.present:
    - name: neutron
    - host: {{ mysql_host }}
    - connection_user: root
    - connection_pass: '{{ mysql_root_password }}'
    - connection_charset: utf8
    - require:
      - service: {{ mysql.service }}
      - pkg: {{ mysql.python }}
      {%- if mysql_root_password %}
      - cmd: mysql_root_password
      {%- endif %}

neutron_grant_localhost:
  mysql_user.present:
    - name: neutron
    - host: localhost
    - password: {{ neutron_dbpass }}
    - connection_user: root
    - connection_pass: '{{ mysql_root_password }}'
    - connection_charset: utf8
    - require:
      - service: {{ mysql.service }}
      - pkg: {{ mysql.python }}
      {%- if mysql_root_password %}
      - cmd: mysql_root_password
      {%- endif %}

  mysql_grants.present:
    - grant: all privileges
    - database: neutron.*
    - user: neutron
    - host: localhost
    - connection_user: root
    - connection_pass: '{{ mysql_root_password }}'
    - connection_charset: utf8
    - require:
      - service: {{ mysql.service }}
      - pkg: {{ mysql.python }}
      {%- if mysql_root_password %}
      - cmd: mysql_root_password
      {%- endif %}

neutron_grant_all:
  mysql_user.present:
    - name: neutron 
    - host: '%'
    - password: {{ neutron_dbpass }}
    - connection_user: root
    - connection_pass: '{{ mysql_root_password }}'
    - connection_charset: utf8
    - require:
      - service: {{ mysql.service }}
      - pkg: {{ mysql.python }}
      {%- if mysql_root_password %}
      - cmd: mysql_root_password
      {%- endif %}

  mysql_grants.present:
    - grant: all privileges
    - database: neutron.*
    - user: neutron
    - host: '%'
    - connection_user: root
    - connection_pass: '{{ mysql_root_password }}'
    - connection_charset: utf8
    - require:
      - service: {{ mysql.service }}
      - pkg: {{ mysql.python }}
      {%- if mysql_root_password %}
      - cmd: mysql_root_password
      {%- endif %}

###
# 2. Create Identity service credentials for Networking:
###

neutron_user:
  keystone.user_present:
    - name: neutron
    - password: {{ neutron_pass }}
    - email: devops@workstation-02.mgmt
    - roles:
      - service:  # tenant
        - admin   # role
    - connection_token: {{ admin_token }}

neutron_network_service:
  keystone.service_present:
    - name: neutron
    - service_type: network
    - description: 'OpenStack Networking'
    - connection_token: {{ admin_token }}

neutron_api_endpoint:
  keystone.endpoint_present:
    - name: neutron
    - publicurl: http://{{ controller }}:9696
    - internalurl: http://{{ controller }}:9696
    - adminurl: http://{{ controller }}:9696
    - region: regionOne
    - connection_token: {{ admin_token }}

###
# Install networking components
###

openstack_neutron:
  pkg.installed:
    - name: openstack-neutron

openstack_neutron_ml2:
  pkg.installed:
    - name: openstack-neutron-ml2

python_neutronclient:
  pkg.installed:
    - name: python-neutronclient

###
# Configure networking server component
###

###
# 1. Configure networking to use the database:
###

neutron_controller_conf_1:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: database
    - parameter: connection
    - value: mysql://neutron:{{ neutron_dbpass }}@{{ mysql_host }}/neutron

###
# 2. Configure Networking to use the Identity service for authentication:
###

neutron_controller_conf_2:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: auth_strategy
    - value: keystone

neutron_controller_conf_3:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_uri
    - value: http://{{ controller }}:5000

neutron_controller_conf_4:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_host
    - value: {{ controller }}

neutron_controller_conf_5:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_port
    - value: '35357'

neutron_controller_conf_6:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: auth_protocol
    - value: http

neutron_controller_conf_7:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: admin_tenant_name
    - value: service

neutron_controller_conf_8:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: admin_user
    - value: neutron

neutron_controller_conf_9:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: keystone_authtoken
    - parameter: admin_password
    - value: {{ neutron_pass }}

###
# 3. Configure Networking to use the message broker
###

neutron_controller_conf_10:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: rpc_backend
    - value: neutron.openstack.common.rpc.impl_qpid

neutron_controller_conf_11:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: qpid_hostname
    - value: {{ controller }}

###
# 4. Configure Networking to notify Compute about network topology changes:
###

neutron_controller_conf_12:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: notify_nova_on_port_status_changes
    - value: 'True'

neutron_controller_conf_13:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: notify_nova_on_port_data_changes
    - value: 'True'

neutron_controller_conf_14:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: nova_url
    - value: http://{{ controller }}:8774/v2

neutron_controller_conf_15:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: nova_admin_username
    - value: nova

neutron_controller_conf_16:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: nova_admin_tenant_id
    - value: {{ nova_admin_tenant_id }}

neutron_controller_conf_17:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: nova_admin_password
    - value: {{ nova_pass }}

neutron_controller_conf_18:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: nova_admin_auth_url
    - value: http://{{ controller }}:35357/v2.0

###
# 5. Configure Networking to use the Modular Layer 2 (ML2) plug-in and associated services:
###

neutron_controller_conf_19:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: core_plugin
    - value: ml2

neutron_controller_conf_20:
  openstack_config.present:
    - filename: /etc/neutron/neutron.conf
    - section: DEFAULT
    - parameter: service_plugins
    - value: router

###
# configure the Modular Layer 2 (ML2) plug-in
###

neutron_controller_conf_21:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2
    - parameter: type_drivers
    - value: gre

neutron_controller_conf_22:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2
    - parameter: tenant_network_types 
    - value: gre

neutron_controller_conf_23:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2
    - parameter: mechanism_drivers 
    - value: openvswitch

neutron_controller_conf_24:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: ml2_type_gre
    - parameter: tunnel_id_ranges
    - value: 1:1000

neutron_controller_conf_25:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: securitygroup
    - parameter: firewall_driver
    - value: neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

neutron_controller_conf_26:
  openstack_config.present:
    - filename: /etc/neutron/plugins/ml2/ml2_conf.ini
    - section: securitygroup
    - parameter: enable_security_group
    - value: 'True'

###
# configure Compute to use Networking
###

neutron_controller_conf_27:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: network_api_class 
    - value: nova.network.neutronv2.api.API

neutron_controller_conf_28:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_url
    - value: http://{{ controller }}:9696

neutron_controller_conf_29:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_auth_strategy
    - value: keystone

neutron_controller_conf_30:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_admin_tenant_name
    - value: service

neutron_controller_conf_31:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_admin_username
    - value: neutron

neutron_controller_conf_32:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_admin_password
    - value: {{ neutron_pass }}

neutron_controller_conf_33:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: neutron_admin_auth_url
    - value: http://{{ controller }}:35357/v2.0

neutron_controller_conf_34:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: linuxnet_interface_driver
    - value: nova.network.linux_net.LinuxOVSInterfaceDriver

neutron_controller_conf_35:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: firewall_driver
    - value: nova.virt.firewall.NoopFirewallDriver

neutron_controller_conf_36:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: security_group_api
    - value: neutron

###
# finalize installation
###

###
# 1. The Networking service initialization scripts expect a symbolic link /etc/neutron/plugin.ini pointing to the configuration file associated with your chosen plug-in. 
###

/etc/neutron/plugin.ini:
  file.symlink:
    - name: /etc/neutron/plugin.ini
    - target: /etc/neutron/plugins/ml2/ml2_conf.ini

###
# 2. Restart the Compute services:
###

openstack_nova_api_service:
  service.running:
    - name: openstack-nova-api
    - enable: True

openstack_nova_scheduler_service:
  service.running:
    - name: openstack-nova-scheduler
    - enable: True

openstack_nova_conductor_service:
  service.running:
    - name: openstack-nova-conductor
    - enable: True


###
# 3. Start the Networking service and configure it to start when the system boots:
###

openstack_neutron_server_running:
  service.running:
    - name: neutron-server
    - enable: True

openstack_neutron_server_enabled_on_boot:
  service.enabled:
    - name: neutron-server


###
# TODO: On the controller node, configure Compute to use the metadata service:

neutron_controller_metadata_1:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: service_neutron_metadata_proxy
    - value: 'true'

neutron_controller_metadata_2:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: metadata_proxy_shared_secret
    - value: {{ metadata_secret }}

# TODO: On the controller node, restart the Compute API service: openstack-nova-api

