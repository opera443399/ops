#!/bin/bash
#
# 2018/7/7

default_test_repeat_times=10
default_test_target_action="rollout"
default_etcd_endpoints="http://10.250.3.100:2379"
default_etcd_prefix="/cicd"
d_root="/data/server/k8s-deploy"
f_log="${d_root}/logs/.confd.log"

do_test_reload_diff() {
  local count="$1"
  local target_key_field="$2"
  local target_key="${default_etcd_prefix}/${target_key_field}/trigger"
  cd ${d_root}
  echo >logs/.confd.log
  rm -fv logs/${target_key_field}.cmd/*.log
  sleep 1s
  for i in `seq 1 ${count}`; do
    echo -n "第 [$i] 次 PUT 操作: "
    json_data="
{
  \"action\":\"deploy\",
  \"k8sNamespace\":\"ns-demo1-dev\",
  \"appName\":\"demo1\",
  \"svcName\":\"gateway\",
  \"imageTag\":\"v1-diff-$i\"
}
"
    ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${default_etcd_endpoints}" put "${target_key}" "${json_data}"
  done
  sleep 1s
  echo "+ [验证] 测试重复次数预期为: ${count} 次"
  echo -n "-- [DEBUG Key updated]: "
  cat logs/.confd.log |grep -c 'DEBUG Key updated'
  echo -n "-- [DEBUG in sync]: "
  cat logs/.confd.log |grep -c 'in sync'
  echo -n "-- [DEBUG out of sync]: "
  cat logs/.confd.log |grep -c 'out of sync'
  echo -n "-- [DEBUG Running]: "
  cat logs/.confd.log |grep -c 'DEBUG Running'
  echo -n "-- [set image]: "
  cat logs/${target_key_field}.cmd/*.log |grep -c 'set image'

}

do_test_reload_not_change() {
  local count="$1"
  local target_key_field="$2"
  local target_key="${default_etcd_prefix}/${target_action}/trigger"
  cd ${d_root}
  echo >logs/.confd.log
  rm -fv logs/${target_key_field}.cmd/*.log
  sleep 1s
  for i in `seq 1 ${count}`; do
    echo -n "第 [$i] 次 PUT 操作: "
    json_data="
{
  \"action\":\"undo\",
  \"k8sNamespace\":\"ns-demo1-dev\",
  \"appName\":\"demo1\",
  \"svcName\":\"gateway\",
  \"imageTag\":\"v2-the-same\"
}
"
    ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${default_etcd_endpoints}" put "${target_key}" "${json_data}"
  done
  sleep 1s
  echo "+ [验证] 测试重复次数预期为: ${count} 次"
  echo -n "-- [DEBUG Key updated]: "
  cat logs/.confd.log |grep -c 'DEBUG Key updated'
  echo -n "-- [DEBUG in sync]: "
  cat logs/.confd.log |grep -c 'in sync'
  echo -n "-- [DEBUG out of sync]: "
  cat logs/.confd.log |grep -c 'out of sync'
  echo -n "-- [DEBUG Running]: "
  cat logs/.confd.log |grep -c 'DEBUG Running'
  echo -n "-- [set image]: "
  cat logs/${target_key_field}.cmd/*.log |grep -c 'set image'

}

do_cleanup_undo() {
  local target_key="${default_etcd_prefix}/undo"
  ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${default_etcd_endpoints}" del "${target_key}"
  rm -fv "${d_root}/reload/undo.cmd"
}

do_start() {
  do_cleanup_undo
  /usr/local/bin/confd -log-level debug -backend etcdv3 -node "${default_etcd_endpoints}" -watch >>${f_log} 2>&1 &
}

do_stop() {
  kill $(ps -ef |grep '/usr/local/bin/confd -log-level debug -backend etcdv3' |grep -v grep |awk '{print $2}')
}

do_status() {
  ps -ef |grep '/usr/local/bin/confd -log-level debug -backend etcdv3' |grep -v grep
  echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
  tail ${f_log}
  echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
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
  test)
    [ -z $2 ] && repeat_times="${default_test_repeat_times}" || repeat_times="$2"
    [ -z $3 ] && target_action="${default_test_target_action}" || target_action="$3"
    echo '_________________________________test: diff tag'
    do_test_reload_diff ${repeat_times} ${target_action}
    echo '_________________________________test: same tag'
    do_test_reload_not_change ${repeat_times} ${target_action}
    ;;
  *)
    cat <<"_EOF"

USAGE:

    $0 [start|stop|restart|status]"

    $0 [test] [repeat_times] [target_action]"

_EOF
    ;;
esac
