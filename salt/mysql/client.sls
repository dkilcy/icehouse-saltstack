{% from "mysql/map.jinja" import mysql with context %}

mysql-client:
  pkg.installed:
    - name: {{ mysql.client }}

