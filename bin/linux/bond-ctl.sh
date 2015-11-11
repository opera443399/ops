#!/bin/bash
# 
# 2015/10/16

### 调整网卡绑定和桥接的配置
# 假设正常情况下，em2启用，em3未启用
# 计划调整：
# 增加br1，使用em2的ip
# 增加bond1，成员为em2+em3，桥接到br1, 参数：'mode=5 miimon=100'
# 即：
# em2+em3=bond1 -> br1
#

do_on() {
    cd /etc/sysconfig/network-scripts/ 
    ifdown em2

    cat <<'_EOF' >ifcfg-bond1
DEVICE=bond1
BONDING_OPTS='mode=5 miimon=100'
BRIDGE=br1
ONBOOT=yes
MTU=1500
NM_CONTROLLED=no
HOTPLUG=no
_EOF

    cat <<'_EOF' >ifcfg-br1
DEVICE=br1
TYPE=Bridge
DELAY=0
STP=off
ONBOOT=yes
IPADDR=10.60.200.86
NETMASK=255.255.255.0
BOOTPROTO=none
MTU=1500
DEFROUTE=yes
NM_CONTROLLED=no
HOTPLUG=no
_EOF

    cat <<'_EOF' >ifcfg-em2
DEVICE=em2
MASTER=bond1
SLAVE=yes
ONBOOT=yes
MTU=1500
NM_CONTROLLED=no
_EOF


    cat <<'_EOF' >ifcfg-em3
DEVICE=em3
MASTER=bond1
SLAVE=yes
ONBOOT=yes
MTU=1500
NM_CONTROLLED=no
_EOF

    ifup bond1
    ifup br1
}

do_off() {
    cd /etc/sysconfig/network-scripts/ 
    ifdown br1
    ifdown bond1
    echo -bond1 >/sys/class/net/bonding_masters
    rm -f ifcfg-bond1 ifcfg-br1

    cat <<'_EOF' >ifcfg-em2 && ifup em2
DEVICE=em2
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=none
IPADDR=10.60.200.86
NETMASK=255.255.255.0
_EOF

    cat <<'_EOF' >ifcfg-em3
DEVICE=em3
TYPE=Ethernet
ONBOOT=no
NM_CONTROLLED=yes
BOOTPROTO=dhcp
_EOF

    ifup em2
}


case $1 in
    on|off)
        do_$1
        echo 'DONE. About 20 seconds delay to wait for testing.'
        ;;
    *)
        echo "usage: $0 on|off"
        ;;
esac
