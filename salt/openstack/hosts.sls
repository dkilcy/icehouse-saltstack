controller-01:
  host.present:
    - ip: 10.0.0.11
    - names:
      - controller-01.mgmt
      - controller-01

network-01:
  host.present:
    - ip: 10.0.0.21
    - names:
      - network-01.mgmt
      - network-01

compute-01:
  host.present:
    - ip: 10.0.0.31
    - names:
      - compute-01.mgmt
      - compute-01

