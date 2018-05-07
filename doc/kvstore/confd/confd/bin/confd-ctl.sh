#!/bin/bash
#
# 2018/4/27

f_log="/data/server/swarm-deploy/logs/.confd.log"

do_cleanup_undo() {
  grep 'prefix=' /data/server/swarm-deploy/temp.cmd/*.undo >/dev/null 2>&1 || return
  for key in $(grep 'prefix=' /data/server/swarm-deploy/temp.cmd/*.undo |awk -F'=' '{print $2}'); do
    echo "cleanup etcd key: ${key}"
    ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "http://10.250.3.100:2379" del ${key}
  done
  rm -f /data/server/swarm-deploy/temp.cmd/*.undo
}

do_start() {
  do_cleanup_undo
  /usr/local/bin/confd -log-level debug -backend etcdv3 -node http://10.250.3.100:2379 -watch >>${f_log} 2>&1 &
}

do_stop() {
  kill $(ps -ef |grep '/usr/local/bin/confd -log-level debug -backend etcdv3 -node http://10.250.3.100:2379 -watch' |grep -v grep |awk '{print $2}')
}

do_status() {
  ps -ef |grep '/usr/local/bin/confd -log-level debug -backend etcdv3 -node http://10.250.3.100:2379 -watch' |grep -v grep
  echo '#############################################################'
  tail ${f_log}
  echo '#############################################################'
}

case $1 in
  start|stop)
    do_$1
    do_status
    ;;
  status)
    do_$1
    ;;
  restart)
    do_stop
    sleep 1
    do_start
    sleep 1
    do_status
    ;;
  *)
    echo $"$0 [start|stop|restart|status]"
    ;;
esac
