/etc/hosts:
  file.append:
    - text: 
      - '192.168.56.253  salt-m.office.test'
      - '192.168.56.254  mirrors.office.test'
      - "127.0.0.1       {{ grains['id'] }}"
