## 安装mysql-server，以及对应的zabbix监控相关文件。
# 
# via pc @ 2015/8/13

Percona-Server:
  pkg.installed:
## for local-office.repo
#
    - fromrepo: office,base,repo
    - name: zabbix-agent
    - skip_verify: True
    - refresh: True
    - pkgs:
## for percona-server
#      
      - Percona-Server-55-debuginfo
      - Percona-Server-client-55
      - Percona-Server-devel-55
      - Percona-Server-server-55
      - Percona-Server-shared-55
      - Percona-Server-test-55
      - percona-zabbix-templates
## for zabbix
# Scripts are installed to /var/lib/zabbix/percona/scripts
# Templates are installed to /var/lib/zabbix/percona/templates
#
# /var/lib/zabbix/percona/scripts:
# total 64
# -rwxr-xr-x 1 root root  1251 Jul 21  2014 get_mysql_stats_wrapper.sh
# -rwxr-xr-x 1 root root 58226 Jul 21  2014 ss_get_mysql_stats.php
#
# /var/lib/zabbix/percona/templates:
# total 284
# -rw-r--r-- 1 root root  18866 Jul 21  2014 userparameter_percona_mysql.conf
# -rw-r--r-- 1 root root 269258 Jul 21  2014 zabbix_agent_template_percona_mysql_server_ht_2.0.9-sver1.1.4.xml
# 
      - php
      - php-mysql

percona-mysql-cnf:
  file.managed:
    - name: /etc/my.cnf
    - source: salt://conf.d/mysql/my.cnf
    - mode: 644
    - require:
      - pkg: Percona-Server

percona-mysql-data:
  file.directory:
    - name: /data/mysql
    - user: mysql
    - group: mysql
    - mode: 755
    - makedirs: True
    - require:
      - pkg: Percona-Server

percona-mysql-init-and-run:
## Installing MySQL system tables
# PLEASE REMEMBER TO SET A PASSWORD FOR THE MySQL root USER !
# /usr/bin/mysqladmin -u root password 'new-password'
  cmd.run:
    - name: /usr/bin/mysql_install_db
    - onlyif:
      - d_mysql=$(grep 'datadir' /etc/my.cnf |cut -d'=' -f2);
        d_mysql_install="${d_mysql}/mysql";
        test ! -d ${d_mysql_install}
  service.running:
    - name: mysql
    - enable: True
    - require:
      - pkg: Percona-Server

## for zabbix
percona-mysql-zabbix-php:
  file.managed:
    - name: /etc/php.ini
    - source: salt://conf.d/mysql/percona_zabbix_php.ini
    - mode: 755
    - require:
      - pkg: Percona-Server

