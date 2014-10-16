###
# Install the Compute agent for Telemetry
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/ceilometer-install-nova.html
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
# 1. Install the Telemetry service on the compute node:
###

openstack_ceilometer_compute:
  pkg.installed:
    - name: openstack-ceilometer-compute

python_ceilometerclient:
  pkg.installed:
    - name: python-ceilometerclient

python_pecan:
  pkg.installed:
    - name: python-pecan

###
# 2. Set the following options in the /etc/nova/nova.conf file: 
###

ceilometer_compute_conf_1:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: instance_usage_audit
    - value: 'True'

ceilometer_compute_conf_2:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: instance_usage_audit_period
    - value: hour

ceilometer_compute_conf_3:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: notify_on_state_change
    - value: vm_and_task_state

ceilometer_compute_conf_4:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: notification_driver
    - value: nova.openstack.common.notifier.rpc_notifier

# TODO: hack for multi value
ceilometer_compute_conf_5a:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: notification_driver1
    - value: ceilometer.compute.nova_notifier

ceilometer_compute_conf_5b:
  file.replace:
    - name: /etc/nova/nova.conf
    - path: /etc/nova/nova.conf
    - pattern: 'notification_driver1'
    - repl: 'notification_driver'

ceilometer_compute_conf_6:
  openstack_config.present:
    - filename: /etc/nova/nova.conf
    - section: DEFAULT
    - parameter: rpc_backend
    - value: qpid

###
# 3. Restart the Compute service:
###

nova_ceilometer_compute_service:
  service.running:
    - name: openstack-nova-compute
    - enable: True
    - watch:
      - file: /etc/nova/nova.conf

###
# 4. You must set the secret key that you defined previously. The Telemetry service nodes share this key as a shared secret:
###

ceilometer_conf_1:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: publisher
    - parameter: metering_secret
    - value: {{ ceilometer_token }}

###
# 5. Configure the QPid access:
###

ceilometer_conf_2:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: DEFAULT
    - parameter: rpc_backend
    - value: ceilometer.openstack.common.rpc.impl_qpid

ceilometer_conf_3:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: DEFAULT
    - parameter: qpid_hostname
    - value: {{ controller }}

###
# 6. Add the Identity service credentials:
###

ceilometer_conf_4:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: auth_host
    - value: {{ controller }}

ceilometer_conf_5:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: admin_user
    - value: ceilometer

ceilometer_conf_6:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: admin_tenant_name
    - value: service

ceilometer_conf_7:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: auth_protocol
    - value: http

ceilometer_conf_8:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: keystone_authtoken
    - parameter: admin_password
    - value: {{ ceilometer_pass }}

ceilometer_conf_9:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: service_credentials
    - parameter: os_username
    - value: ceilometer

ceilometer_conf_10:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: service_credentials
    - parameter: os_tenant_name
    - value: service

ceilometer_conf_11:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: service_credentials
    - parameter: os_password
    - value: {{ ceilometer_pass }}

ceilometer_conf_12:
  openstack_config.present:
    - filename: /etc/ceilometer/ceilometer.conf
    - section: service_credentials
    - parameter: os_auth_url
    - value: http://{{ controller }}:5000/v2.0

###
# 7. Start the service and configure it to start when the system boots:
###

openstack_ceilometer_compute_service:
  service.running:
    - name: openstack-ceilometer-compute
    - enable: True
    - watch.file:
      - name: /etc/ceilometer/ceilometer.conf

openstack_ceilometer_compute_service_enabled_on_boot:
  service.enabled:
    - name: openstack-ceilometer-compute

