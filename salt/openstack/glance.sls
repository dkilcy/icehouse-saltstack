###
# Install the Image Service
# Icehouse
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/glance-install.html
# author: David Kilcy
###

{% from "mysql/map.jinja" import mysql with context %}

{% set mysql_host = salt['pillar.get']('openstack:controller') %}
{% set controller = salt['pillar.get']('openstack:controller') %}
{% set admin_token = salt['pillar.get']('openstack:ADMIN_TOKEN') %}
{% set mysql_root_password = salt['pillar.get']('mysql:server:root_password', salt['grains.get']('server_id')) %}

{% set glance_pass = salt['pillar.get']('openstack:GLANCE_PASS') %}
{% set glance_dbpass = salt['pillar.get']('openstack:GLANCE_DBPASS') %}

###
# 1. Install the Image Service on the controller node
###

openstack_glance:
  pkg.installed:
    - name: openstack-glance

python_glanceclient:
  pkg.installed:
    - name: python-glanceclient

###
# 2. The Image Service stores information about images in a database
###

glance_conf_1:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: database
    - parameter: connection
    - value: 'mysql://glance:{{ glance_dbpass }}@{{ mysql_host }}/glance'      

glance_conf_2:
  openstack_config.present:
    - filename: /etc/glance/glance-registry.conf
    - section: database
    - parameter: connection
    - value: 'mysql://glance:{{ glance_dbpass }}@{{ mysql_host }}/glance'           

###
# 3. Create glance DB user
###

glance_db:
  mysql_database.present:
    - name: glance
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

glance_grant_localhost:
  mysql_user.present:
    - name: glance
    - host: localhost
    - password: {{ glance_dbpass }}
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
    - database: glance.*
    - user: glance
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

glance_grant_all:
  mysql_user.present:
    - name: glance 
    - host: '%'
    - password: {{ glance_dbpass }}
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
    - database: glance.*
    - user: glance
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
# 4. Create the database tables for the Image Service:
###

glance_db_sync:
  cmd.run:
    - name: glance-manage db_sync

###
# 5. Create a glance user that the Image Service can use to authenticate with the Identity service. 
# Choose a password and specify an email address for the glance user. 
# Use the service tenant and give the user the admin role:
###

glance_user:
  keystone.user_present:
    - name: glance
    - password: {{ glance_pass }}
    - email: devops@workstation-02.mgmt
    - roles:
      - service:  # tenant
        - admin   # role
    - connection_token: {{ admin_token }}

###
# 6. Configure the Image Service to use the Identity Service for authentication.
###

glance_api_conf_1:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: keystone_authtoken
    - parameter: auth_uri
    - value: http://{{ controller }}:5000

glance_api_conf_2:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: keystone_authtoken
    - parameter: auth_host
    - value: {{ controller }}

glance_api_conf_3:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: keystone_authtoken
    - parameter: auth_port
    - value: '35357'

glance_api_conf_4:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: keystone_authtoken
    - parameter: auth_protocol
    - value: http

glance_api_conf_5:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: keystone_authtoken
    - parameter: admin_tenant_name
    - value: service

glance_api_conf_6:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: keystone_authtoken
    - parameter: admin_user
    - value: glance

glance_api_conf_7:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: keystone_authtoken
    - parameter: admin_password
    - value: {{ glance_pass }}

glance_api_conf_8:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: paste_deploy
    - parameter: flavor
    - value: keystone

glance_registry_conf_1:
  openstack_config.present:
    - filename: /etc/glance/glance-registry.conf
    - section: keystone_authtoken
    - parameter: auth_uri
    - value: http://{{ controller }}:5000

glance_api_registry_2:
  openstack_config.present:
    - filename: /etc/glance/glance-registry.conf
    - section: keystone_authtoken
    - parameter: auth_host
    - value: {{ controller }}

glance_api_registry_3:
  openstack_config.present:
    - filename: /etc/glance/glance-registry.conf
    - section: keystone_authtoken
    - parameter: auth_port
    - value: '35357'

glance_api_registry_4:
  openstack_config.present:
    - filename: /etc/glance/glance-registry.conf
    - section: keystone_authtoken
    - parameter: auth_protocol
    - value: http

glance_api_registry_5:
  openstack_config.present:
    - filename: /etc/glance/glance-registry.conf
    - section: keystone_authtoken
    - parameter: admin_tenant_name
    - value: service

glance_api_registry_6:
  openstack_config.present:
    - filename: /etc/glance/glance-registry.conf
    - section: keystone_authtoken
    - parameter: admin_user
    - value: glance

glance_api_registry_7:
  openstack_config.present:
    - filename: /etc/glance/glance-registry.conf
    - section: keystone_authtoken
    - parameter: admin_password
    - value: {{ glance_pass }}

glance_api_registry_8:
  openstack_config.present:
    - filename: /etc/glance/glance-registry.conf
    - section: paste_deploy
    - parameter: flavor
    - value: keystone

###
# 7. Register the Image Service with the Identity service so that other OpenStack services can locate it.
# Register the service and create the endpoint:
###

glance_identity_service:
  keystone.service_present:
    - name: glance 
    - service_type: image
    - description: 'OpenStack Image Service'
    - connection_token: {{ admin_token }}

glance_api_endpoint:
  keystone.endpoint_present:
    - name: glance
    - publicurl: http://{{ controller }}:9292
    - internalurl: http://{{ controller }}:9292
    - adminurl: http://{{ controller }}:9292
    - region: regionOne
    - connection_token: {{ admin_token }}

###
# 8. Start the glance-api and glance-registry services and configure them to start when the system boots
###

/var/log/glance:
  file.directory:
    - user: glance 
    - group: glance 
    - mode: 750
    - create: True

/var/log/glance/api.log:
  file.managed:
    - user: glance
    - group: glance
    - mode: '644'
    - create: True

/var/log/glance/registry.log:
  file.managed:
    - user: glance
    - group: glance
    - mode: '644'
    - create: True

glance_api_enabled_on_boot:
  service.enabled:
    - name: openstack-glance-api

glance_registry_enabled_on_boot:
  service.enabled:
    - name: openstack-glance-registry

glance_api_service:
  service.running:
    - name: openstack-glance-api
    - enable: True

glance_registry_service:
  service.running:
    - name: openstack-glance-registry
    - enable: True

