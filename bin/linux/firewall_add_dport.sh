#!/bin/bash
# 
# 2015/4/10

s_port=10050

echo "[-] add dport ${s_port}"
mkdir -p /home/liudu_ops/conf
cd /home/liudu_ops/conf/
iptables-save >rc.firewall.txt
grep "dport ${s_port} -j" rc.firewall.txt || sed -i "/-A INPUT -j REJECT --reject-with icmp-host-prohibited/i\-A INPUT -p tcp -m state --state NEW -m tcp --dport ${s_port} -j ACCEPT" rc.firewall.txt
iptables-restore rc.firewall.txt
echo "[-] iptables status:"
iptables -nL

echo "[-] check it before running 'service iptables save'"
