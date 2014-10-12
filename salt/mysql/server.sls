{% from "mysql/map.jinja" import mysql with context %}

{% set eth0 = salt['grains.get']('ip_interfaces:eth0', 'localhost') %}
{% set os_family = salt['grains.get']('os_family', None) %}
{% set mysql_root_password = salt['pillar.get']('mysql:server:root_password', salt['grains.get']('server_id')) %}

{% if os_family == 'Debian' %}

mysql_debconf:
  debconf.set:
    - name: mysql-server
    - data:
        'mysql-server/root_password': {'type': 'password', 'value': '{{ mysql_root_password }}'}
        'mysql-server/root_password_again': {'type': 'password', 'value': '{{ mysql_root_password }}'}
        'mysql-server/start_on_boot': {'type': 'boolean', 'value': 'true'}
    - require_in:
      - pkg: {{ mysql.service }} 

{% elif os_family == 'RedHat' %}

mysql_root_password:
  cmd.run:
    - name: mysqladmin --user root password '{{ mysql_root_password|replace("'", "'\"'\"'") }}'
    - unless: mysql --user root --password='{{ mysql_root_password|replace("'", "'\"'\"'") }}' --execute="SELECT 1;"
    - require:
      - service: {{ mysql.service }}

{% endif %}

mysql_server:
  pkg.installed:
    - name: {{ mysql.server }}
    {% if os_family == 'Debian' %}
    - require:
      - debconf: mysql_debconf
    {% endif %}

  service.running:
    - name: {{ mysql.service }}
    - enable: True
    - restart: True
    - watch:
      - file: {{ mysql.config }}
      - pkg: mysql-server

mysql_config:
  file.managed:
    - name: {{ mysql.config }}
    - source: salt://mysql/files/my.cnf
    - mode: 644
    - user: root
    - group: root

{{ mysql.config }}:
  file.replace:
    - pattern: ^bind-address=localhost
    - repl: bind-address={{ eth0[0] }}

{% for host in ['localhost', salt['grains.get']('fqdn')] %}
mysql_user_{{ host }}:
  mysql_user.absent:
    - name: ''
    - host: {{ host }}
    - connection_user: root
    - connection_pass: '{{ mysql_root_password }}'
    - connection_charset: utf8
    - require:
      - service: {{ mysql.service }}
      - pkg: {{ mysql.python }}
      {%- if mysql_root_password %}
      - cmd: mysql_root_password
      {%- endif %}
{% endfor %}
