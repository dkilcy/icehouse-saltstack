{% set controller = pillar['openstack']['controller'] %}

auth_setup:
  file.managed:
    - name: /home/devops/auth-openrc.sh
    - user: devops
    - group: devops
    - mode: 755 
    - create: True
    - contents: |
        export METADATA_SECRET={{ pillar['openstack']['METADATA_SECRET'] }}
        export ADMIN_TOKEN={{ pillar['openstack']['ADMIN_TOKEN'] }}
        export ADMIN_PASS={{ pillar['openstack']['ADMIN_PASS'] }}
        export DEMO_PASS={{ pillar['openstack']['DEMO_PASS'] }}
        export KEYSTONE_DBPASS={{ pillar['openstack']['KEYSTONE_DBPASS'] }}
        export GLANCE_DBPASS={{ pillar['openstack']['GLANCE_DBPASS'] }}
        export GLANCE_PASS={{ pillar['openstack']['GLANCE_PASS'] }}
        export NOVA_DBPASS={{ pillar['openstack']['NOVA_DBPASS'] }}
        export NOVA_PASS={{ pillar['openstack']['NOVA_PASS'] }}
        export NEUTRON_DBPASS={{ pillar['openstack']['NEUTRON_DBPASS'] }}
        export NEUTRON_PASS={{ pillar['openstack']['NEUTRON_PASS'] }}

admin_setup:
  file.managed:
    - name: /home/devops/admin-openrc.sh
    - user: devops
    - group: devops
    - mode: 755 
    - create: True
    - contents: |
        export OS_USERNAME=admin
        export OS_PASSWORD=$ADMIN_PASS
        export OS_TENANT_NAME=admin
        export OS_AUTH_URL=http://{{ controller }}:35357/v2.0

demo_setup:
  file.managed:
    - name: /home/devops/demo-openrc.sh
    - user: devops
    - group: devops
    - mode: 755 
    - contents: |
        export OS_USERNAME=demo
        export OS_PASSWORD=$DEMO_PASS
        export OS_TENANT_NAME=demo
        export OS_AUTH_URL=http://{{ controller }}:35357/v2.0

