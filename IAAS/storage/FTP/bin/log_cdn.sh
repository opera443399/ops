#!/bin/bash
# filename: log_cdn.sh
# 
# 2014/11/20
# 
# mkdir -p /home/log/cdn/{log,stat}

action=$1
dt=$2
[ -z ${dt} ] && dt=$(date -d "yesterday" +"%Y-%m-%d")

location="ftp.xxcdn.com"
ftpsvr="ftp://${location}"
d_base="/home/log/cdn"
d_stat="${d_base}/stat"
d_log="${d_base}/log"
f_logdetail="${d_base}/log/download.log"
f_logwget="${d_base}/log/wget.log"

usage() {
    cat <<_EOF

$0 [stat|clean] date

_EOF
}

s_domains="www.xxx.com"
list_domain=(${s_domains})
lens_domain=${#list_domain[@]}

log_download() {
    local s_URL="$1"

    echo "[+] START: `date +"%Y-%m-%d %H:%M:%S"`"
    echo "[-] ready to get: ${s_URL}"
    wget -P ${d_base} --ftp-user=xxx --ftp-password=xxx -m -c -t5 ${s_URL} -a ${f_logwget} -nv
    echo "[-] END: `date +"%Y-%m-%d %H:%M:%S"`"
}

log_stat() {
    for ((i=0;i<$lens_domain;i++))
    do
        local s_URL="${ftpsvr}/${list_domain[$i]}/${dt}*"
        log_download ${s_URL}
        local d_result="${d_stat}/${list_domain[$i]}/${dt}"
        mkdir -p ${d_result} && cd ${d_result}
        local f_pattern="${d_base}/${location}/${list_domain[$i]}/${dt}-*.cn.*"
        ls ${f_pattern}
        zcat ${f_pattern} |awk '{print $7}' |sort |uniq -c |sort -nr >1_uri.log
        
    done
}

log_clean() {
    find ${d_base}/${location} -type -f -mtime +13 -delete
}

case ${action} in
    stat)
        log_clean
        log_stat ${dt} >${f_logdetail} 2>&1 &
        ;;
    clean)
        log_clean
        ;;
    *)
        usage
        ;;
esac
