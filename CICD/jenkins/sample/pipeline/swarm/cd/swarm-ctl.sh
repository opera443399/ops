#!/bin/bash
#
# 2018/12/14

export LANG="en_US.UTF-8"

action="$1"
swarm_env="$2"
app_name="$3"
app_tag="$4"
svc_names="$5"

s_dt=$(date +%Y%m%d_%H%M%S)
f_alert_bin="/usr/local/bin/receiver_wechat.py"

# ---
do_action() {
  set -e
  cd /data/server/demo/${app_name} \
    && /bin/bash deploy.sh snapshot \
    && /bin/bash deploy.sh "${action}" "${swarm_env}" "${app_tag}" "${svc_names}" \
    && rc1=0 || rc1=1

  [ ${rc1} -eq 0 ] && icon=✅ || icon=❎
  ### alert
  echo "[@] ___> 任务结束，通知: wechat"
  msg="
[@] ${action} : ${app_name}-${swarm_env}
[@] tag: ${app_tag}
[@] svc: ${svc_names}

[swarm] job ${icon}
"
  python ${f_alert_bin} "${app_name}-${swarm_env}" "${msg}" && rc2=0 || rc2=1
  exit $(($rc1+rc2))

}

# ---
usage() {
cat<<_EOF

usage: $0 action swarm_env app_name app_tag svc_names

_EOF
}

# ---
case $1 in
  update|rollback)
    do_action
    ;;
  *)
    usage
    ;;
esac
