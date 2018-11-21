dnsmasq:
  pkg.installed: []
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/dnsmasq.d/office.conf
      - file: /etc/dnsmasq.conf

/etc/dnsmasq.d/office.conf:
  file.managed:
    - source: salt://conf.d/dnsmasq/office.conf
  
/etc/dnsmasq.conf:
  file.replace:
    - pattern: '#addn-hosts=/etc/banner_add_hosts'
    - repl: 'addn-hosts=/etc/dnsmasq.d/office.conf'
