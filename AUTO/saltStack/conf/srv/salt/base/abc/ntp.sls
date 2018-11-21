## use local timezone and ntp settings
# 
# via pc @ 2015/8/19

/etc/localtime:
  file.copy:
    - source: /usr/share/zoneinfo/Asia/Shanghai
    - force: True

pkg-ntp-start:
  pkg.installed:
    - name: ntp
  file.managed:
    - name: /etc/ntp.conf
    - source: salt://conf.d/locale/ntp.conf
    - requires:
      - pkg: ntp
  service.running:
    - name: ntpd
    - enable: True
    - reload: True
    - watch:
      - file: /etc/ntp.conf
    - require:
      - pkg: ntp
    - require_in:
      - file: /etc/sysconfig/ntpd

/etc/sysconfig/ntpd:
  file.managed:
    - source: salt://conf.d/locale/sysconfig_ntpd

