#!/bin/bash
# 
# 2015/11/4

## 安装ntp服务，更新timezone，localtime，clock
do_init() {
    echo "[+] 安装ntp服务，更新timezone，localtime，clock"
    yum -y install ntp
    echo "[*] timezone: Asia/Shanghai"
    mv -fv /etc/localtime /etc/localtime.old
    ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    mv -fv /etc/sysconfig/clock /etc/sysconfig/clock.old
    echo 'ZONE="Asia/Shanghai"' >/etc/sysconfig/clock 
}

## 配置 NTP 服务端
function do_s() {
    echo "[+] 更新配置： /etc/ntp.conf"
    cp -afv /etc/ntp.conf /etc/ntp.conf.old
    cat <<_EOF >/etc/ntp.conf
driftfile /var/lib/ntp/drift
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict -6 ::1
 
 
server stdtime.gov.hk iburst 
server cn.pool.ntp.org iburst
server 0.asia.pool.ntp.org iburst 
server 1.asia.pool.ntp.org iburst 
server 2.asia.pool.ntp.org iburst 
 
 
# 如果本机作为ntp服务器时，局域网的ntp客户端同步时遇到错误：
# no server suitable for synchronization found
# 则不妨debug一下：ntpdate -d ntp_server_ip
# 可以观察到，Server dropped: strata too high，stratum 16
# 这是因为这个ntp_server_ip的服务还未和其中定义的server完成同步
# 此时，可以做如下的配置，将local时间作为ntp服务提供给客户端。 
server 127.127.1.0
fudge 127.127.1.0 stratum 8
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
_EOF


    echo "[*] 更新配置： /etc/sysconfig/iptables"
    sed -i.backup '/-A INPUT -i lo -j ACCEPT/a\## udp related \
-A INPUT -p udp -m state --state NEW -m udp --dport 123 -j ACCEPT \
# \
' /etc/sysconfig/iptables
    service iptables reload

    service ntpd stop
    echo "[*] 尝试同步："
    /usr/sbin/ntpdate stdtime.gov.hk
    service ntpd start
    chkconfig ntpd on
    chkconfig --list |grep ntpd
}



## 配置 ntp 客户端 通过 crontab 来同步时间
function do_c1() {
    service ntpd stop
    echo "[+] 尝试同步： $1..."
    ntpdate $1
    chkconfig ntpd off
    chkconfig --list |grep ntpd

    echo "[*] 更新配置：/var/spool/cron/$(whoami)"

    cat <<_NTP >>/var/spool/cron/$(whoami)
# [daily]
*/20 * * * * /usr/sbin/ntpdate $1 >/dev/null &
_NTP

    echo -e "[*] 新的配置如下：\n#################"
    echo '[crontab]'
    crontab -l

}



## 配置 ntp 客户端 通过 ntp 来同步时间
function do_c2() {
    echo "[+] 更新配置： /etc/ntp.conf"
    cp -afv /etc/ntp.conf /etc/ntp.conf.old
    cat <<_EOF >/etc/ntp.conf
driftfile /var/lib/ntp/drift
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict -6 ::1
 
server $1 iburst
server stdtime.gov.hk iburst 
server cn.pool.ntp.org iburst
server 0.asia.pool.ntp.org iburst 
server 1.asia.pool.ntp.org iburst 
server 2.asia.pool.ntp.org iburst 
 
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
_EOF

    service ntpd stop
    echo "[*] 尝试同步："
    /usr/sbin/ntpdate $1
    service ntpd start
    chkconfig ntpd on
    chkconfig --list |grep ntpd
}


usage() {
    cat <<_USAGE

Usage:
    $0 init                  安装ntp服务，更新timezone，localtime，clock
    $0 s                     配置为ntp服务器
    $0 c1 domain_or_ip       配置为ntp客户端，指定ntp服务器的ip，通过ntpdate在crontab中定时同步
    $0 c2 domain_or_ip       配置为ntp客户端，指定ntp服务器的ip，通过ntp服务同步

_USAGE
}

case $1 in
    s|init)
        do_$1
        ;;
    c1|c2)
        do_$1 $2
        ;;
    *)
        usage
        ;;
esac
