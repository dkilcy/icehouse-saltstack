###
# Configure the Image Service for Telemetry
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/ceilometer-install-glance.html
# Icehouse
# Author: David Kilcy
###

###
# 1. To retrieve image samples, you must configure the Image Service to send notifications to the bus.
###

glance_ceilometer_conf_1:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: DEFAULT
    - parameter: notification_driver
    - value: messaging

glance_ceilometer_conf_2:
  openstack_config.present:
    - filename: /etc/glance/glance-api.conf
    - section: DEFAULT
    - parameter: rpc_backend
    - value: qpid

###
# 2. Restart the Image Services with their new settings:
###

openstack_glance_api_service:
  service.running:
    - name: openstack-glance-api
    - reload: True
    - watch.file:
      - name: /etc/glance/glance-api.conf

openstack_glance_registry_service:
  service.running:
    - name: openstack-glance-registry
    - reload: True
    - watch.file:
      - name: /etc/glance/glance-api.conf

