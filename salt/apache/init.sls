
apache:
  pkg.installed:
    - name: {{ pillar['pkgs']['apache'] }}
  service.running:
    - name: {{ pillar['pkgs']['apache'] }}
    - enable: True
    - restart: True
    - watch:
      - pkg: {{ pillar['pkgs']['apache'] }}

