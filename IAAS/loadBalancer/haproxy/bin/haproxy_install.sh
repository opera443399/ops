#!/bin/bash
#
# 2015/4/29
# init haproxy cfg/rsyslog/logrotate
 
log() {
  echo "[-] install"
  rpm -qa |grep haproxy && [ $? = 0 ]
  [ $? = 0 ] && which haproxy || yum -y install haproxy
  echo "[-] configure rsyslog and logrotate"
 
  # rsyslog
  cat >/etc/rsyslog.d/haproxy.conf  <<_CONF
# 启用 UDP port 514
\$ModLoad imudp
\$UDPServerRun 514 
local2.=info -/var/log/haproxy/haproxy.log
local2.notice -/var/log/haproxy/haproxy.admin
# 其他类型的不记录
local2.* ~
_CONF
  service rsyslog restart
 
  # logrotate
  [ -f /etc/logrotate.d/haproxy ] || cat > /etc/logrotate.d/haproxy <<_CONF
/var/log/haproxy/haproxy.log {
    daily
    rotate 10
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
        /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}
_CONF
 
  echo "[*] done."
}
 
cfg() {
  echo "[-] initialize cfg file, saved to: /etc/haproxy/haproxy.cfg"
 
  mv /etc/haproxy/haproxy.cfg /etc/haproxy/old.haproxy.cfg
  # add haproxy example conf
  cat >/etc/haproxy/haproxy.cfg <<_CONF
#---------------------------------------------------------------------
# HAProxy 配置
#
 
#---------------------------------------------------------------------
# 全局设置
#--------------------------------------------------------------------- 
global
    # # 使用系统的rsyslog记录日志
   #
    log         127.0.0.1 local2
 
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
 
    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats
 
#---------------------------------------------------------------------
# 通用设置， 'listen' 和 'backend' 部分会用到，如果没单独指定的话
#--------------------------------------------------------------------- 
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull     # 不记录空连接
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    1m
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
 
    balance roundrobin                      # lb算法
  
#---------------------------------------------------------------------
# 配置  stat
#---------------------------------------------------------------------
listen admin_stat
    bind    127.0.0.1:12202
    mode    http
    option  httplog
    log     global
    stats   refresh 30s                   # 统计页面自动刷新时间
    stats   uri /status                   # 统计页面URL
    stats   realm Haproxy\ Statistics     # 统计页面密码框上提示文本
    stats   auth admin:password           # 统计页面用户名和密码设置
    stats   hide-version                  # 隐藏统计页面上HAProxy的版本信息
  
#---------------------------------------------------------------------
# 配置  TCP
#---------------------------------------------------------------------
# backend
#   check   -- 允许对该服务器进行健康检查
#   weight  -- 设置权重
#   inter   -- 连续两次健康检查间隔，单位为毫秒(ms)，默认值 2000(ms)
#   rise    -- 指定多少次连续成功的健康检查后，即可认定该服务器处于可操作状态，默认值 2
#   fall    -- 指定多少次不成功的健康检查后，认为服务器为当掉状态，默认值 3
#   server s_name s_ip:port check weight inter 2000 rise 2 fall 3
 
listen  p80
    bind    *:80
    mode    tcp
    option  tcplog
    server  app1 192.168.1.240:80 check
 
#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend  main *:5000
    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js
 
    use_backend static          if url_static
    default_backend             app
 
#---------------------------------------------------------------------
# static backend for serving up images, stylesheets and such
#---------------------------------------------------------------------
backend static
    balance     roundrobin
    server      static 127.0.0.1:4331 check
 
#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend app
    balance     roundrobin
    server  app1 127.0.0.1:5001 check
    server  app2 127.0.0.1:5002 check
    server  app3 127.0.0.1:5003 check
    server  app4 127.0.0.1:5004 check
  
_CONF
 
  echo "[*] done."
  service haproxy check
 
}
 
usage() {
  cat <<_USAGE
 
initialize haproxy log and config
 
Usage:
    $0 [log|cfg]
 
_USAGE
}
 
##########
case $1 in
  log|cfg)
    $1
    ;;
  *)
    usage
    ;;
esac
