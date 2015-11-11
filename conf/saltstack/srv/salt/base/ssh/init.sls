openssh-clients:
  pkg.installed: []

openssh-server:
  pkg.installed: []

sshd:
  service.running:
    - enable: True
    - require:
      - pkg: openssh-clients
      - pkg: openssh-server
      - file: /etc/ssh/sshd_config

/etc/ssh/sshd_config:
  file.managed:
    - source: salt://conf.d/ssh/sshd_config
    - require:
      - pkg: openssh-server
