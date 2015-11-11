## update sysctl
# 
# via pc @ 2015/8/12

basic-limits:
  file.managed:
    - name: /etc/security/limits.d/my-limits.conf
    - source: salt://conf.d/systemtuning/my-limits.conf

basic-sysctl:
  file.append:
    - name: /etc/sysctl.conf
    - source: salt://conf.d/systemtuning/sysctl.conf

basic-rc-local:
  file.append:
    - name: /etc/rc.local
    - source: salt://conf.d/systemtuning/rc-local.conf

basic-modprobe-dist:
  file.append:
    - name: /etc/modprobe.d/dist.conf
    - source: salt://conf.d/systemtuning/modprobe-dist.conf
