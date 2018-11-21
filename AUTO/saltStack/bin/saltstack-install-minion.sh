#!/bin/bash
#
# 2015/4/21

salt_m=salt-m.office.test
yum install salt-minion -y

cp -a /etc/salt/minion /etc/salt/minion.bak
cat <<_EOF >/etc/salt/minion
master: ${salt_m}
id: $(hostname)

_EOF

service salt-minion start
cat /etc/salt/minion
