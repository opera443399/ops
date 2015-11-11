base:
  'tvm-yum':
    - dnsmasq
    - crontab
    - web
  'tvm-zabbix':
    - mysql.server
    - zabbix.server
    - zabbix.web

  '*':
    - abc
    - monit
    - postfix
    - salt.minion
    - ssh
    - vim
    - zabbix.agent
    #- ops.bin
