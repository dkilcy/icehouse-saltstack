
iptables_stop:
  service.running:
    - name: iptables
    - dead: True
    - enable: False

