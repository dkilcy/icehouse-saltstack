###
# Install the Telemetry module
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/ceilometer-install.html
# Icehouse
# Author: David Kilcy
###

{% set controller = salt['pillar.get']('openstack:controller') %}
{% set admin_token = salt['pillar.get']('openstack:ADMIN_TOKEN') %}

{% set ceilometer_pass = salt['pillar.get']('openstack:CEILOMETER_PASS') %}
{% set ceilometer_dbpass = salt['pillar.get']('openstack:CEILOMETER_DBPASS') %}
{% set ceilometer_token = salt['pillar.get']('openstack:CEILOMETER_PASS') %}

{% set mongodb_host = salt['pillar.get']('openstack:controller') %}

###
# 1. Install the Telemetry service on the controller node:
###

openstack_ceilometer_api:
  pkg.installed:
    - name: openstack-ceilometer-api

openstack_ceilometer_collector:
  pkg.installed:
    - name: openstack-ceilometer-collector

openstack_ceilometer_notification:
  pkg.installed:
    - name: openstack-ceilometer-notification

openstack_ceilometer_central:
  pkg.installed:
    - name: openstack-ceilometer-central

openstack_ceilometer_alarm:
  pkg.installed:
    - name: openstack-ceilometer-alarm

python_ceilometerclient:
  pkg.installed:
    - name: python-ceilometerclient

###
# 2. The Telemetry service uses a database to store information. Specify the location of the database in the 
#    configuration file. The examples use a MongoDB database on the controller node:
###

mongodb-server:
  pkg.installed:
    - name: mongodb-server

mongodb:
  pkg.installed:
    - name: mongodb

###
# 3. Configure MongoDB to make it listen on the controller management IP address.  Edit the /etc/mongodb.conf file and modify the bind_ip key:
###

mongodb_conf_bindIp:
  file.replace:
    - name: /etc/mongodb.conf
    - path: /etc/mongodb.conf
    - pattern: 'bind_ip = 127.0.0.1'
    - repl: 'bind_ip = 0.0.0.0'

###
# 4. Start the MongoDB server and configure it to start when the system boots:
###

mongodb_service:
  service.running:
    - name: mongod

mongodb_service_enabled_on_boot:
  service.enabled:
    - name: mongod

###
# 5. Create the database and a ceilometer database user:
###

mongodb_user_create:
  cmd.run:
    - name: "mongo --host {{ controller }} --eval 'db = db.getSiblingDB(\"ceilometer\"); db.addUser({user: \"ceilometer\", pwd: \"{{ ceilometer_dbpass }}\", roles: [ \"readWrite\", \"dbAdmin\" ]})'"

###
# 6. Configure the Telemetry service to use the database:
###

ceilometer_mongodb_service:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: database
    - parameter: connection
    - value: 'mongodb://ceilometer:{{ ceilometer_dbpass }}@{{ mongodb_host }}:27017/ceilometer'

###
# 7. You must define a secret key that is used as a shared secret among Telemetry service nodes.
###

ceilometer_mongodb_token:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: publisher
    - parameter: metering_secret
    - value: '{{ ceilometer_token }}'

###
# 8. Configure the Qpid access:
###

ceilometer_qpid:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: DEFAULT
    - parameter: rpc_backend
    - value: ceilometer.openstack.common.rpc.impl_qpid

###
# 9. Create a ceilometer user that the Telemetry service uses to authenticate with the Identity Service. 
#    Use the service tenant and give the user the admin role:
###

keystone_ceilometer_user:
  keystone.user_present:
    - name: ceilometer
    - password: {{ ceilometer_pass }}
    - email: devops@workstation-02.mgmt
    - roles:
      - service:  # tenant
        - admin   # role
    - connection_token: {{ admin_token }}

###
# 10. Configure the Telemetry service to authenticate with the Identity Service.
###

keystone_ceilometer_auth:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: DEFAULT
    - parameter: auth_strategy
    - value: keystone

###
# 11. Add the credentials to the configuration files for the Telemetry service:
###

ceilometer_controller_conf_1:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: auth_host
    - value: {{ controller }}

ceilometer_controller_conf_2:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: admin_user
    - value: ceilometer

ceilometer_controller_conf_3:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: admin_tenant_name
    - value: service

ceilometer_controller_conf_4:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: auth_protocol
    - value: http

ceilometer_controller_conf_5:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: auth_uri
    - value: http://{{ controller }}:5000

ceilometer_controller_conf_6:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: admin_password
    - value: {{ ceilometer_pass }}

ceilometer_controller_conf_7:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: service_credentials
    - parameter: os_auth_url
    - value: http://{{ controller }}:5000/v2.0

ceilometer_controller_conf_8:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: service_credentials
    - parameter: os_username
    - value: ceilometer

ceilometer_controller_conf_9:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: service_credentials
    - parameter: os_tenant_name
    - value: service

ceilometer_controller_conf_10:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: service_credentials
    - parameter: os_password
    - value: {{ ceilometer_pass }}

###
# 12. Register the Telemetry service with the Identity Service so that other OpenStack services can locate it.
###

ceilometer_identity_service:
  keystone.service_present:
    - name: ceilometer
    - service_type: metering
    - description: 'OpenStack Telemetry'
    - connection_token: {{ admin_token }}

ceilometer_api_endpoint:
  keystone.endpoint_present:
    - name: ceilometer
    - publicurl: http://{{ controller }}:8777
    - internalurl: http://{{ controller }}:8777
    - adminurl: http://{{ controller }}:8777
#    - region: regionOne
    - connection_token: {{ admin_token }}

###
# 13. Start the openstack-ceilometer-api, openstack-ceilometer-central, openstack-ceilometer-collector and
#     services and configure them to start when the system boots:
###

openstack_ceilometer_api_service:
  service.running:
    - name: openstack-ceilometer-api

openstack_ceilometer_collector_service:
  service.running:
    - name: openstack-ceilometer-collector

openstack_ceilometer_notification_service:
  service.running:
    - name: openstack-ceilometer-notification

openstack_ceilometer_central_service:
  service.running:
    - name: openstack-ceilometer-central

openstack_ceilometer_alarm_evaluator_service:
  service.running:
    - name: openstack-ceilometer-alarm-evaluator

openstack_ceilometer_alarm_notifier_service:
  service.running:
    - name: openstack-ceilometer-alarm-notifier


openstack_ceilometer_api_service_enabled_on_boot:
  service.running:
    - name: openstack-ceilometer-api

openstack_ceilometer_collector_service_enabled_on_boot:
  service.running:
    - name: openstack-ceilometer-collector

openstack_ceilometer_notification_service_enabled_on_boot:
  service.running:
    - name: openstack-ceilometer-notification

openstack_ceilometer_central_service_enabled_on_boot:
  service.running:
    - name: openstack-ceilometer-central

openstack_ceilometer_alarm_evaluator_service_enabled_on_boot:
  service.running:
    - name: openstack-ceilometer-alarm-evaluator

openstack_ceilometer_alarm_notifier_service_enabled_on_boot:
  service.running:
    - name: openstack-ceilometer-alarm-notifier


