## 安装zabbix-agent
# 
# via pc @ 2015/8/17

zabbix-agent:
  pkg.installed:
## for local-office.repo
#
    - fromrepo: office
    - name: zabbix-agent
    - skip_verify: True
    - refresh: True
    - version: 2.4.6-1.el6

userparameter_mysql.conf:
  file.absent:
    - name: /etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf
    - require:
      - pkg: zabbix-agent

zabbix-agent-start:
  service.running:
    - name: zabbix-agent
    - enable: True
    - restart: True
    - watch:
      - file: /etc/zabbix/zabbix_agentd.conf
      - file: /etc/zabbix/zabbix_agentd.d
    - require:
      - pkg: zabbix-agent

zabbix-agent-conf:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.conf
    - source: salt://conf.d/zabbix/zabbix_agentd.conf
    - template: jinja
    - require:
      - pkg: zabbix-agent

zabbix-agent-dir:
  file.recurse:
    - name: /etc/zabbix/zabbix_agentd.d
    - source: salt://conf.d/zabbix/zabbix_agentd.d/
    - mkdirs: True
    - require:
      - pkg: zabbix-agent

zabbix-agent-scripts:
  file.recurse:
    - name: /etc/zabbix/scripts
    - source: salt://conf.d/zabbix/scripts/
    - mkdirs: True
    - require:
      - pkg: zabbix-agent

zabbix-agent-conf-monit:
  file.managed:
    - name: /etc/monit.d/zabbix-agent.conf
    - source: salt://conf.d/monit/zabbix-agent.conf
    - require:
      - pkg: zabbix-agent



## for iptables
zabbix-10050:
  cmd.run:
    - unless: grep 'zabbix-agent added' /etc/sysconfig/iptables
    - name:
        sed -i
        '/-A INPUT -i lo -j ACCEPT/a\## zabbix-agent added.
        \n-A INPUT -p tcp -m state --state NEW -m tcp --dport 10050 -j ACCEPT
        \n-A INPUT -p udp -m state --state NEW -m udp --dport 10050 -j ACCEPT
        ' /etc/sysconfig/iptables
    - require:
      - pkg: zabbix-agent

zabbix-10050-tcp:
  cmd.run:
    - unless: /sbin/iptables -nL |grep 'tcp dpt:10050'
    - name: /sbin/iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 10050 -j ACCEPT
    - require:
      - pkg: zabbix-agent

zabbix-10050-udp:
  cmd.run:
    - unless: /sbin/iptables -nL |grep 'udp dpt:10050'
    - name: /sbin/iptables -I INPUT -p udp -m state --state NEW -m udp --dport 10050 -j ACCEPT
    - require:
      - pkg: zabbix-agent

