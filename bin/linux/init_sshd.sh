#!/bin/bash
#
# 2015/4/20

# SSH

s_port=932

echo "[-] add dport ${s_port}"
mkdir -p /home/liudu_ops/conf
cd /home/liudu_ops/conf/
iptables-save >rc.firewall.txt
grep "dport ${s_port} -j" rc.firewall.txt || sed -i "/-A INPUT -j REJECT --reject-with icmp-host-prohibited/i\-A INPUT -p tcp -m state --state NEW -m tcp --dport ${s_port} -j ACCEPT" rc.firewall.txt
iptables-restore rc.firewall.txt
echo "[-] iptables status:"
iptables -nL

echo "[-] check it before running 'service iptables save'"


setenforce 0

cat  > /etc/ssh/sshd_config.new << _EOF
Port 22
Port ${s_port}
Protocol 2
SyslogFacility AUTHPRIV
#PasswordAuthentication no
ChallengeResponseAuthentication no
GSSAPIAuthentication no
GSSAPICleanupCredentials no
UsePAM yes
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS
X11Forwarding yes
UseDNS no
Subsystem       sftp    /usr/libexec/openssh/sftp-server
_EOF

mv /etc/ssh/sshd_config /etc/ssh/sshd_config.old
mv /etc/ssh/sshd_config.new /etc/ssh/sshd_config

echo '#########################################'
echo ''
cat /etc/ssh/sshd_config
echo ''
echo '#########################################'
echo '注意：selinux禁用并重启后再更改port，以免连接不上ssh端口；建议后续再禁用root，password登录，改用key登录；'

echo '[note] check config file and run : service sshd reload'

