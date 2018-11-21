salt-minion:
  pkg.installed: []
  service.running:
    - enable: True
