#!/bin/bash
#
# 2016/9/18

## 请根据实际环境来预先配置LAN和WAN的子网掩码和网关IP
LAN_PREFIX=24
LAN_GATEWAY=10.50.200.1
WAN_PREFIX=25
WAN_GATEWAY=4.3.2.1

usage() {
    cat <<_EOF
初始化vm的网络和主机名。

用法：
    $0 hostname ip_lan
    $0 hostname ip_lan ip_wan

默认：
    ip_lan 在 eth0 上
    ip_wan 在 eth1 上

注：
    脚本执行完毕后，将重启服务器
_EOF
}


## 设置网卡配置文件
set_ifcfg(){
    ###如果是测试生成的网卡配置文件是否符合预期，请调整 file_ifcfg 这个变量指向的文件名
    ## 例如:
    #local file_ifcfg="test-ifcfg-$1"
    local file_ifcfg="/etc/sysconfig/network-scripts/ifcfg-$1"
    cat <<_EOF >${file_ifcfg}
DEVICE=$1
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=$2
PREFIX=$3
GATEWAY=$4
NM_CONTROLLED=no
#DEFROUTE=yes
_EOF
}

function set_lan(){
    set_ifcfg eth0 $1 ${LAN_PREFIX} ${LAN_GATEWAY}
}

function set_wan(){
    set_ifcfg eth1 $1 ${WAN_PREFIX} ${WAN_GATEWAY}
}


## 设置域名
function set_host(){
    sed -i '/HOSTNAME=/d' /etc/sysconfig/network
    echo "HOSTNAME=$1" >>/etc/sysconfig/network
    echo -ne "\n[-] hostname 已更新: [$(hostname)"
    hostname $1
    echo -e "] -> [$(hostname)]\n"
}

if [ $# -eq 0 ];then
    usage
    exit 1
elif [ $# -eq 2 ];then
    set_host $1
    set_lan $2
elif [ $# -eq 3 ];then
    set_host $1
    set_lan $2
    set_wan $3
fi


echo -e "\n[-] IP 已更新，即将重启服务。\n"
sleep 2s

###如果是测试生成的网卡配置文件是否符合预期，请注释掉以下全部内容###
## 重启 netowrk 服务
service network restart

## 从某个web服务上下载脚本来执行其他操作，例如加入某些管理平台。
#curl http://web_server/some_thing_to_do.sh |bash -

## 清理 history 和重启系统。
history -c
reboot
