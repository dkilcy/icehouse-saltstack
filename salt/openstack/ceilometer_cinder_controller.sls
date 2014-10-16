###
# Add the Block Storage service agent for Telemetry
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/ceilometer-install-cinder.html
# Icehouse
# Author: David Kilcy
###

###
# 1. To retrieve volume samples, you must configure the Block Storage service to send notifications to the bus.
#    Run the following commands on the controller and volume nodes:
###

ceilometer_controller_cinder_conf_1:
  openstack_config.present:
    - filename: /etc/cinder/cinder.conf
    - section: DEFAULT
    - parameter: control_exchange
    - value: cinder

ceilometer_controller_cinder_conf_2:
  openstack_config.present:
    - filename: /etc/cinder/cinder.conf
    - section: DEFAULT
    - parameter: notification_driver
    - value: cinder.openstack.common.notifier.rpc_notifier

###
# 2. Restart the Block Storage services with their new settings.
#    On the controller node:
###

ceilometer_controller_cinder_api_service:
  service.running:
    - name: openstack-cinder-api
    - enable: True
    - watch.file:
      - name: /etc/cinder/cinder.conf

ceilometer_controller_cinder_scheduler_service:
  service.running:
    - name: openstack-cinder-scheduler
    - enable: True
    - watch.file:
      - name: /etc/cinder/cinder.conf

