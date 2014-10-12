qpid:
  pkg.installed:
    - name: qpid-cpp-server

qpidd:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/qpidd.conf
      - pkg: qpid-cpp-server

/etc/qpidd.conf:
  file.replace:
    - pattern: ^auth=yes
    - repl: auth=no

