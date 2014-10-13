###
# Install the dashboard
#
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/install_dashboard.html
# author: David Kilcy
###

{% set controller = salt['pillar.get']('openstack:controller') %}

###
# 1. Install the dashboard on the node that can contact the Identity Service as root:
###

memcached:
  pkg.installed:
    - name: memcached

python_memcached:
  pkg.installed:
    - name: python-memcached

mod_wsgi:
  pkg.installed:
    - name: mod_wsgi

openstack_dashboard:
  pkg.installed:
    - name: openstack-dashboard

###
# 2. Modify the value of CACHES['default']['LOCATION'] in /etc/openstack-dashboard/local_settings to match the ones set in /etc/sysconfig/memcached.
###

# 'BACKEND' : 'django.core.cache.backends.locmem.LocMemCache', 'LOCATION' : '127.0.0.1:11211',

###
# 3. Update the ALLOWED_HOSTS in local_settings.py to include the addresses you wish to access the dashboard from.
###

local_settings_1:
  file.append:
    - name: /etc/openstack-dashboard/local_settings
    - text:
      - "ALLOWED_HOSTS = [ '{{ controller }}', 'localhost']"

###
# 4. This guide assumes that you are running the Dashboard on the controller node. You can easily run the dashboard on a separate server, by changing the appropriate settings in local_settings.py.
###

###
# 5. Ensure that the SELinux policy of the system is configured to allow network connections to the HTTP server. 
###

# setsebool -P httpd_can_network_connect on

###
# 6. Start the Apache web server and memcached:
###

dashboard_service:
  service.running:
    - name: {{ pillar['pkgs']['apache'] }}
    - enable: True
    - watch: 
      - file: /etc/openstack-dashboard/local_settings

dashboard_service_enabled_on_boot:
  service.enabled:
    - name: {{ pillar['pkgs']['apache'] }}

memcached_service:
  service.running:
    - name: memcached
    - enable: True
    - watch: 
      - file: /etc/openstack-dashboard/local_settings

memcached_service_enabled_on_boot:
  service.enabled:
    - name: memcached

###
# You can now access the dashboard at http://controller/dashboard .
# Login with credentials for any user that you created with the OpenStack Identity Service.
###




