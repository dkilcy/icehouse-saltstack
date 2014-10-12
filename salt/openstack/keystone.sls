###
# Configure the Identity Service
# Icehouse
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/ch_keystone.html
# author: David Kilcy
###

{% from "mysql/map.jinja" import mysql with context %}

{% set mysql_host = salt['pillar.get']('openstack:controller') %}
{% set controller = salt['pillar.get']('openstack:controller') %}
{% set admin_token = salt['pillar.get']('openstack:ADMIN_TOKEN') %}
{% set mysql_root_password = salt['pillar.get']('mysql:server:root_password', salt['grains.get']('server_id')) %}

{% set admin_pass = salt['pillar.get']('openstack:ADMIN_PASS') %}
{% set demo_pass = salt['pillar.get']('openstack:DEMO_PASS') %}

{% set keystone_dbpass = salt['pillar.get']('openstack:KEYSTONE_DBPASS') %}

###
# Install the Identity Service
###

###
# 1. Install the OpenStack Identity Service on the controller node, together with python-keystoneclient 
# (which is a dependency):
###

openstack_keystone:
  pkg.installed:
    - name: openstack-keystone

python_keystoneclient:
  pkg.installed:
    - name: python-keystoneclient

###
# 2. The Identity Service uses a database to store information.
# Specify the location of the database in the configuration file.
##

keystone_conf_1:
  openstack_config.present:
    - filename: /etc/keystone/keystone.conf
    - section: database
    - parameter: connection
    - value: 'mysql://keystone:{{ keystone_dbpass }}@{{ mysql_host }}/keystone'      

###
# 3. Create a keystone database user
###

keystone_db:
  mysql_database.present:
    - name: keystone
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

keystone_grant_localhost:
  mysql_user.present:
    - name: keystone
    - host: localhost
    - password: {{ keystone_dbpass }}
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
    - database: keystone.*
    - user: keystone
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

keystone_grant_all:
  mysql_user.present:
    - name: keystone
    - host: '%'
    - password: {{ keystone_dbpass }}
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
    - database: keystone.*
    - user: keystone
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
# 4. Create the database tables for the Identity Service:
###

keystone_db_sync:
  cmd.run:
    - name: keystone-manage db_sync
#    - require_in:
#      - keystone: keystone_tenants

###
# 5. Define an authorization token to use as a shared secret between the Identity Service and other OpenStack services.
# Use openssl to generate a random token and store it in the configuration file:
###

keystone_conf_2:
  openstack_config.present:
    - filename: /etc/keystone/keystone.conf
    - section: DEFAULT
    - parameter: admin_token
    - value: {{ admin_token }}

###
# 6. By default, Keystone uses PKI tokens. Create the signing keys and certificates and restrict access to the 
# generated data:
###

keystone_pki_setup:
  cmd.run:
    - name: keystone-manage pki_setup --keystone-user keystone --keystone-group keystone

keystone_pki_setup_ssl:
  file.directory:
    - name: /etc/keystone/ssl
    - user: keystone
    - group: keystone
    - mode: 750
    - recurse:
      - user
      - group

###
# 7. Start the Identity Service and enable it to start when the system boots:
###

/var/log/keystone:
  file.directory:
    - user: keystone
    - group: keystone
    - mode: 750
    - create: True

/var/log/keystone/keystone.log:
  file.managed:
    - user: keystone
    - group: keystone
    - mode: '644'
    - create: True

keystone_enabled_on_boot:
  service.enabled:
    - name: openstack-keystone

keystone_service:
  service.running:
    - name: openstack-keystone
    - enable: True

###
#  Define users, tenants, and roles
###

##
# Create tenants and roles
##

keystone_tenants:
  keystone.tenant_present:
    - names:
      - admin
      - demo
      - service
    - connection_token: {{ admin_token }}

keystone_roles:
  keystone.role_present:
    - names:
      - admin
      - _member_
    - connection_token: {{ admin_token }}

##
# Create admin user
##
keystone_admin:
  keystone.user_present:
    - name: admin
    - password: {{ admin_pass }}
    - email: devops@workstation-02.mgmt
    - roles:
      - admin:   # tenants
        - admin  # roles
      - service:
        - admin
        - _member_
      - require:
        - keystone: keystone_tenants
        - keystone: keystone_roles
    - connection_token: {{ admin_token }}

## 
# Create demo user
##
keystone_demo:
  keystone.user_present:
    - name: demo
    - password: {{ demo_pass }}
    - email: devops@workstation-02.mgmt
    - roles:
      - demo:
        - _member_
      - require:
        - keystone: keystone_tenants
        - keystone: keystone_roles
    - connection_token: {{ admin_token }}

##
# Create identity service endpoint
##

keystone_identity_service:
  keystone.service_present:
    - name: keystone
    - service_type: identity
    - description: 'Service Tenant'
    - connection_token: {{ admin_token }}

keystone_api_endpoint:
  keystone.endpoint_present:
    - name: keystone
    - publicurl: 'http://{{ controller }}:5000/v2.0'
    - internalurl: 'http://{{ controller }}:5000/v2.0'
    - adminurl: 'http://{{ controller }}:35357/v2.0'
    - region: regionOne
    - connection_token: {{ admin_token }}

