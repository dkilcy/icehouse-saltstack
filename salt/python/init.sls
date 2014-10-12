{% from "python/map.jinja" import python with context %}

python-dev:
  pkg.installed:
    - name: {{ python.dev }}
   
python-pip:
  pkg.installed:
    - name: python-pip

