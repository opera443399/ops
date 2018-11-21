#!bin/bash
#
# 2018/7/7

s_dt=$(date +%Y%m%d_%H%M%S)
f_dest="$1"
f_log_dir="/data/server/k8s-deploy/logs/$(echo ${f_dest} |awk -F'/' '{print $2}')"
test -d "${f_log_dir}" || mkdir -p "${f_log_dir}"
f_log="${f_log_dir}/${s_dt}.log"

do_confd_reload_cmd() {
  echo
  echo -e "[+] ---------------------------------> [${s_dt}] op=do_confd_reload_cmd"
  echo -e "[-] ___> [CAT_CMD] ${f_dest}"
  echo '##################################################'
  cat ${f_dest}  |grep -v '^$'
  echo '##################################################'
  echo -e "[-] ___> [RUN_CMD] ${f_dest}"
  echo
  sh ${f_dest}
  echo
  echo -e "[-] ___> [EXIT_CODE] $?"
  echo
}

### cleanup
find "${f_log_dir}" -type f -name '*.log' -mmin +10 -delete

do_confd_reload_cmd ${f_dest} >>${f_log} 2>&1 &
