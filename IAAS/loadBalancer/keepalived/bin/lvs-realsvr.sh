#!/bin/bash
# 
# 2015/3/27
# lvs real server
#
# chkconfig:   - 85 15
# description:  control vip on lvs realserver 
 
# Source function library.
. /etc/rc.d/init.d/functions
 
# Source networking configuration.
. /etc/sysconfig/network
 
# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0
 
lockfile="/var/lock/subsys/lvs-real"
   
s_vip='10.0.205.100'
 
start() {
  ifconfig lo:1 ${s_vip} netmask 255.255.255.255 broadcast ${s_vip}
  echo 1 >/proc/sys/net/ipv4/conf/lo/arp_ignore
  echo 2 >/proc/sys/net/ipv4/conf/lo/arp_announce
  echo 1 >/proc/sys/net/ipv4/conf/all/arp_ignore
  echo 2 >/proc/sys/net/ipv4/conf/all/arp_announce
 
  retval=$?
  echo
  [ $retval -eq 0 ] && touch $lockfile
  return $retval
}
 
stop() {
  echo 0 >/proc/sys/net/ipv4/conf/lo/arp_ignore
  echo 0 >/proc/sys/net/ipv4/conf/lo/arp_announce
  echo 0 >/proc/sys/net/ipv4/conf/all/arp_ignore
  echo 0 >/proc/sys/net/ipv4/conf/all/arp_announce
  ifconfig lo:1 down
 
  retval=$?
  echo
  [ $retval -eq 0 ] && rm -f $lockfile
  return $retval
}
 
status() {
  ip a |grep inet |grep -v inet6  
}
 
case $1 in  
  start)
    start
    status
    ;;
  stop)
    stop
    status
    ;;
  status)
    status
    ;;
  *)  
    echo $"Usage: $0 {start|stop|status}"
    exit 2 
esac
