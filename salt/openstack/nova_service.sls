###
# Confgure Compute services
# - Install Compute controller services
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/nova-controller.html
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
# Install Compute controller services
###

###
# 1. Install the Compute packages necessary for the controller node.
###

openstack_nova_api:
  pkg.installed:
    - name: openstack-nova-api

openstck_nova_cert:
  pkg.installed:
    - name: openstack-nova-cert

openstack_nova_conductor:
  pkg.installed:
    - name: openstack-nova-conductor

openstack_nova_console:
  pkg.installed:
    - name: openstack-nova-console

openstack_nova_novncproxy:
  pkg.installed:
    - name: openstack-nova-novncproxy

openstack_nova_scheduler:
  pkg.installed:
    - name: openstack-nova-scheduler

python_novaclient:
  pkg.installed:
    - name: python-novaclient

###
# 2. Configure Compute with the database location and credentials. 
###

nova_conf_1:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: database
    - parameter: connection
    - value: 'mysql://nova:{{ nova_dbpass }}@{{ mysql_host }}/nova'

###
# 3. Set these configuration keys to configure Compute to use the Qpid message broker:
###

nova_conf_2:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: rpc_backend
    - value: qpid

nova_conf_3:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: qpid_hostname
    - value: {{ controller }}

###
# 4. Set the my_ip, vncserver_listen, and vncserver_proxyclient_address configuration options to the management 
# interface IP address of the controller node:
###

nova_conf_4:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: my_ip
    - value: {{ ip_addr }} 

nova_conf_5:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: vncserver_listen
    - value: {{ ip_addr }} 

nova_conf_6:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: vncserver_proxyclient_address
    - value: {{ ip_addr }}

###
# 5. Create a nova database user:
###

nova_db:
  mysql_database.present:
    - name: nova
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

nova_grant_localhost:
  mysql_user.present:
    - name: nova
    - host: localhost
    - password: {{ nova_dbpass }}
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
    - database: nova.*
    - user: nova
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

nova_grant_all:
  mysql_user.present:
    - name: nova
    - host: '%'
    - password: {{ nova_dbpass }}
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
    - database: nova.*
    - user: nova
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
# 6. Create the Compute service tables:
###

nova_db_sync:
  cmd.run:
    - name: nova-manage db sync

###
# 7. Create a nova user that Compute uses to authenticate with the Identity Service. 
# Use the service tenant and give the user the admin role:
###

nova_user:
  keystone.user_present:
    - name: nova
    - password: {{ nova_pass }}
    - email: devops@workstation-02.mgmt
    - roles:
      - service:  # tenant
        - admin   # role
    - connection_token: {{ admin_token }}

###
# 8. Configure Compute to use these credentials with the Identity Service running on the controller.
###

nova_api_conf_1:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: auth_strategy
    - value: keystone

nova_api_conf_2:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: auth_uri
    - value: http://{{ controller }}:5000

nova_api_conf_3:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: auth_host
    - value: {{ controller }}

nova_api_conf_4:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: auth_protocol
    - value: http

nova_api_conf_5:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: auth_port
    - value: '35357'

nova_api_conf_6:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: admin_user
    - value: nova

nova_api_conf_7:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: admin_tenant_name
    - value: service

nova_api_conf_8:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: keystone_authtoken
    - parameter: admin_password
    - value: {{ nova_pass }}

###
# 9. Register the service and specify the endpoint:
###

nova_identity_service:
  keystone.service_present:
    - name: nova
    - service_type: compute
    - description: 'OpenStack Compute'
    - connection_token: {{ admin_token }}

nova_api_endpoint:
  keystone.endpoint_present:
    - name: nova
    - publicurl: http://{{ controller }}:8774/v2/%(tenant_id)s
    - internalurl: http://{{ controller }}:8774/v2/%(tenant_id)s
    - adminurl: http://{{ controller }}:8774/v2/%(tenant_id)s
    - region: regionOne
    - connection_token: {{ admin_token }}

###
# 10. Start Compute services and configure them to start when the system boots:
###

nova_api_service:
  service.running:
    - name: openstack-nova-api
    - enable: True

nova_cert_service:
  service.running:
    - name: openstack-nova-cert
    - enable: True

nova_consoleauth_service:
  service.running:
    - name: openstack-nova-consoleauth
    - enable: True

nova_scheduler_service:
  service.running:
    - name: openstack-nova-scheduler
    - enable: True

nova_conductor_service:
  service.running:
    - name: openstack-nova-conductor
    - enable: True

nova_novncproxy_service:
  service.running:
    - name: openstack-nova-novncproxy
    - enable: True

###

nova_api_enabled_on_boot:
  service.enabled:
    - name: openstack-nova-api

nova_cert_enabled_on_boot:
  service.enabled:
    - name: openstack-nova-cert

nova_consoleauth_enabled_on_boot:
  service.enabled:
    - name: openstack-nova-consoleauth

nova_scheduler_on_boot:
  service.enabled:
    - name: openstack-nova-scheduler

nova_conductor_enabled_on_boot:
  service.enabled:
    - name: openstack-nova-conductor

nova_novncproxy_enabled_on_boot:
  service.enabled:
    - name: openstack-nova-novncproxy

