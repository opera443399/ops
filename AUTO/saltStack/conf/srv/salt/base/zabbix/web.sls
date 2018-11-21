## 安装zabbix-web-mysql
# 
# via pc @ 2015/8/13

zabbix-web-mysql:
  pkg.installed:
## for local-office.repo
#
    - fromrepo: office,epel,base
    - name: zabbix-web-mysql
    - skip_verify: True
    - refresh: True
  service.running:
    - name: httpd
    - enable: True
    - reload: True
    - watch:
      - file: zabbix-web-conf
      - file: zabbix-web-php
    - require:
      - pkg: zabbix-web-mysql

zabbix-web-conf:
  file.managed:
    - name: /etc/httpd/conf.d/zabbix.conf
    - source: salt://conf.d/zabbix/httpd_zabbix.conf
    - require:
      - pkg: zabbix-web-mysql

zabbix-web-php:
  file.managed:
    - name: /etc/php.ini
    - source: salt://conf.d/zabbix/php_zabbix.ini
    - require:
      - pkg: zabbix-web-mysql

## for iptables
zabbix-80:
  cmd.run:
    - unless: grep 'zabbix-web added' /etc/sysconfig/iptables
    - name:
        sed -i
        '/-A INPUT -i lo -j ACCEPT/a\## zabbix-web added.
        \n-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
        ' /etc/sysconfig/iptables
    - require:
      - pkg: zabbix-web-mysql

zabbix-80-tcp:
  cmd.run:
    - unless: /sbin/iptables -nL |grep 'tcp dpt:80'
    - name: /sbin/iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
    - require:
      - pkg: zabbix-web-mysql

