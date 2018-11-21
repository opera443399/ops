#!/bin/sh
#
# rc.firewall - 初始化内网网关配置
#
# PC@20140620
#

###########################################################################
# 1. 配置

#####
# 1.1 配置 外网WAN
#
INET_IP="1.2.3.4"
INET_IFACE="em2"
INET_IP2="21.43.56.78"
INET_IFACE2="em2:1"

#####
# 1.2 配置 内网LAN
# 接口，IP和子网掩码，可以用VLSM 
#
LAN_IP="192.168.100.254"
LAN_IP_RANGE="192.168.100.0/24"
LAN_IFACE="em1"

#####
# 1.3 配置 DMZ
#

#####
# 1.4 配置 iptables路径
#
IPTABLES="/sbin/iptables"


###########################################################################
# 2. 模块

#####
# 2.1 初始化
#
/sbin/depmod -a

#####
# 2.2 必须
#
/sbin/modprobe ip_tables
/sbin/modprobe ip_conntrack
/sbin/modprobe iptable_filter
/sbin/modprobe iptable_mangle
/sbin/modprobe iptable_nat
/sbin/modprobe ipt_limit
/sbin/modprobe ipt_state


###########################################################################
# 3. 配置 /proc

#####
# 3.1 开启IP转发
#
echo "1" > /proc/sys/net/ipv4/ip_forward

###########################################################################
# 4. 设置规则

######
# 4.1 表 Filter
#

# 4.1.1 设置策略，先保存旧的配置信息，再清空表 Filter
# 
#iptables-save >/root/rc.firewall.txt.save.old
#service iptables status >/root/rc.firewall.txt.status.old

$IPTABLES -P INPUT ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -F

# 4.1.2 建立自定义链
#
$IPTABLES -N bad_tcp_packets
$IPTABLES -N allowed
$IPTABLES -N tcp_packets
$IPTABLES -N udp_packets

# 4.1.3 增加规则到链中
#
# 链 bad_tcp_packets
#
$IPTABLES -A bad_tcp_packets -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j REJECT --reject-with tcp-reset 
$IPTABLES -A bad_tcp_packets -p tcp ! --syn -m state --state NEW -j DROP

# 链 allowed
#
$IPTABLES -A allowed -p TCP --syn -j ACCEPT
$IPTABLES -A allowed -p TCP -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A allowed -p TCP -j DROP

# 链 tcp_packets
#
$IPTABLES -A tcp_packets -p TCP -m tcp --dport 22 -j allowed
$IPTABLES -A tcp_packets -p TCP -m tcp --dport 80 -j allowed

# 链 udp_packets
#
#$IPTABLES -A udp_packets -p udp -m udp --dport 123 -j ACCEPT 

# 4.1.4 链 INPUT
#
# 规则：bad_tcp_packets 过滤
#
$IPTABLES -A INPUT -p tcp -j bad_tcp_packets

# 规则：从本地进入
#
$IPTABLES -A INPUT -i $LAN_IFACE -s $LAN_IP_RANGE -j ACCEPT
$IPTABLES -A INPUT -i lo -j ACCEPT

# 规则：从外网进入
#
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -p icmp -j ACCEPT
$IPTABLES -A INPUT -p TCP -j tcp_packets
$IPTABLES -A INPUT -p UDP -j udp_packets
$IPTABLES -A INPUT -j REJECT --reject-with icmp-host-prohibited 

# 4.1.5 链 FORWARD
#
# 规则：bad_tcp_packets 过滤
#
$IPTABLES -A FORWARD -p tcp -j bad_tcp_packets

# 允许转发
#
$IPTABLES -A FORWARD -i $LAN_IFACE -j ACCEPT
$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A FORWARD -j REJECT --reject-with icmp-host-prohibited

# 4.1.6 链 OUTPUT
#

######
# 4.2 表 nat
#

# 4.2.1 设置策略，先清除旧的配置
#
$IPTABLES -t nat -F

# 4.2.2 建立自定义链
#

# 4.2.3 增加规则到链中
#

# 4.2.4 链 PREROUTING
#

# 4.2.5 链 POSTROUTING
# 启用简单的IP 转发和NAT
#
$IPTABLES -t nat -A POSTROUTING -o $INET_IFACE -j SNAT --to-source $INET_IP
$IPTABLES -t nat -A POSTROUTING -o $INET_IFACE2 -j SNAT --to-source $INET_IP2

# 4.2.6 链 OUTPUT chain
#

######
# 4.3 表 mangle
#

# 4.3.1 设置策略
#

# 4.3.2 建立自定义链
#

# 4.3.3 增加规则到链中
#

# 4.3.4 链 PREROUTING
#

# 4.3.5 链 INPUT
#

# 4.3.6 链 FORWARD
#

# 4.3.7 链 OUTPUT
#

# 4.3.8 链 POSTROUTING
#


###########################################################################
# 5. 显示规则

service iptables status
#iptables-save >/root/rc.firewall.txt.save
#service iptables status >/root/rc.firewall.txt.status
