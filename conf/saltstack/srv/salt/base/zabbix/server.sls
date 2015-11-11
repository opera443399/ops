## 安装mysql db for zabbix, zabbix-server
# 
# via pc @ 2015/8/13

zabbix-server-mysql-create:
  cmd.run:
## for zabbix db
# mysql> create database zabbix character set utf8 collate utf8_bin;
# msyql> grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
    - onlyif: s_zbx_pwd='zabbix'; zbx_tables=$(mysql -uzabbix -p${s_zbx_pwd} -e 'use zabbix;show tables;' |wc -l); test $zbx_tables -eq 0;
    - name: cd /usr/share/doc/zabbix-server-mysql-2.4.6/create/;
        s_zbx_pwd='zabbix';
        mysql -uzabbix -p${s_zbx_pwd} zabbix <schema.sql;
        mysql -uzabbix -p${s_zbx_pwd} zabbix <images.sql;
        mysql -uzabbix -p${s_zbx_pwd} zabbix <data.sql;


zabbix-server-mysql:
  pkg.installed:
## for local-office.repo
#
    - fromrepo: office,epel,base
    - name: zabbix-server-mysql
    - skip_verify: True
    - refresh: True
    - require_in:
      - file: /etc/zabbix/zabbix_server.conf
  service.running:
    - name: zabbix-server
    - enable: True
    - restart: True
    - watch:
      - file: zabbix-server-conf
    - require:
      - pkg: zabbix-server-mysql


zabbix-server-conf:
  file.managed:
    - name: /etc/zabbix/zabbix_server.conf
    - source: salt://conf.d/zabbix/zabbix_server.conf
    - template: jinja


## for iptables
zabbix-10051:
  cmd.run:
    - unless: grep 'zabbix-server added' /etc/sysconfig/iptables
    - name:
        sed -i
        '/-A INPUT -i lo -j ACCEPT/a\## zabbix-server added.
        \n-A INPUT -p tcp -m state --state NEW -m tcp --dport 10051 -j ACCEPT
        \n-A INPUT -p udp -m state --state NEW -m udp --dport 10051 -j ACCEPT
        ' /etc/sysconfig/iptables

zabbix-10051-tcp:
  cmd.run:
    - unless: /sbin/iptables -nL |grep 'tcp dpt:10051'
    - name: /sbin/iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 10051 -j ACCEPT

zabbix-10051-udp:
  cmd.run:
    - unless: /sbin/iptables -nL |grep 'udp dpt:10051'
    - name: /sbin/iptables -I INPUT -p udp -m state --state NEW -m udp --dport 10051 -j ACCEPT

