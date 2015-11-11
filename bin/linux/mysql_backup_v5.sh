#!/bin/bash
#
# 2014/12/16
# v5.1
# increment backup, with timestamp, compressed, with master & slave.

######################
s_port="$1"
s_action="$2"
s_slave="$3"

#####  配置参数  ######
##
f_my_cnf="/data/svr/mariadb-10.0.14-linux-x86_64/my.cnf.${s_port}"
d_bak_base="/data/backup/mysql/${s_port}"
s_copies=6
s_password="xxx"
##

####################### 用法
function usage() {
    cat <<EOF


[-] 用法: $0 port [full|incr|full_tar|full_stream] [slave]

$0 3306 full &              全备份，未压缩；完成后压缩前一天的备份；
$0 3306 incr &              增量备份，未压缩；完成后压缩前一天的备份；
$0 3306 full_tar &          全备份，未压缩；完成后，压缩这个备份；
$0 3306 full_stream &       全备份，边备份边压缩，stream=tar模式；

[-] 针对slave实例：
$0 3306 full slave &
$0 3306 incr slave &
$0 3306 full_tar slave &
$0 3306 full_stream slave &

[-] 针对crontab的配置：
+------------------------------+
# [mysql]
0 0 * * 6 $0 3306 full &
0 0 * * 0-5 $0 3306 incr &
+------------------------------+

EOF
    exit 2
}

#######################
test ${s_port} -gt 0
if [ $? -gt 0 ]; then
    echo "[+] Tips: 端口没有指定或者有误；"
    usage
    exit 3;
fi

if [ -z ${s_slave} ]; then
    s_args="--defaults-file=${f_my_cnf} --host=127.0.0.1 --port=${s_port} --user=root --password=${s_password}"
else
    s_args="--defaults-file=${f_my_cnf} --host=127.0.0.1 --port=${s_port} --user=root --password=${s_password} --slave-info --safe-slave-backup"
fi

d_bak_gz="${d_bak_base}/gz"
d_bak_tmp="${d_bak_base}/tmp"
d_bak_log="${d_bak_base}/log"
d_bak_full="${d_bak_base}/full"
f_bak_stream="${d_bak_full}/mysql-stream-$(date +%F).gz"

[ -d ${d_bak_gz} ] || mkdir -p ${d_bak_gz}
[ -d ${d_bak_tmp} ] || mkdir -p ${d_bak_tmp}
[ -d ${d_bak_log} ] || mkdir -p ${d_bak_log}
[ -d ${d_bak_full} ] || mkdir -p ${d_bak_full}

###################### 清理旧备份
function do_cleanup() {
    echo "[-] `date` delete old files over ${s_copies} days ... "
    find ${d_bak_gz} -type f -name "*.gz" -mtime +${s_copies} -print
    find ${d_bak_gz} -type f -name "*.gz" -mtime +${s_copies} -delete
    find ${d_bak_full} -type f -name "*.gz" -mtime +${s_copies} -print
    find ${d_bak_full} -type f -name "*.gz" -mtime +${s_copies} -delete
    find ${d_bak_log} -type f -name "*.log" -mtime +${s_copies} -print
    find ${d_bak_log} -type f -name "*.log" -mtime +${s_copies} -delete

    echo "[-] `date` done."
}

###################### 压缩今天之前的目录，清理旧备份
function do_tar_yesterday() {
    local s_yesterday=$(date -d "1 day ago" +%F)

    echo "[-] `date` waiting for file compression process ..."
    cd ${d_bak_tmp}
    ls |grep -v "`date +%F`" |xargs -i tar zcf "{}.tar.gz" {} --remove-files
    echo "[-] `date` move: `ls *.gz` to: ${d_bak_gz}"
    mv *.gz ${d_bak_gz}
   
    do_cleanup
}

###################### 压缩指定目录
function do_tar() {
    echo "[-] `date` waiting for file compression process ..."
    cd ${d_bak_full}
    ls |grep -v ".gz" |xargs -i tar zcf "{}.tar.gz" {} --remove-files

    do_cleanup
}

###################### 全备份，未压缩；完成后压缩前一天的备份；
function do_full() {
    echo "[+] `date` +------------------------Start--------------------+"
    innobackupex ${s_args} ${d_bak_tmp}
    echo "[-] `date` +------------------------cleanup------------------+"
    do_tar_yesterday
    echo "[-] `date` +------------------------The End------------------+"
}

###################### 增量备份，未压缩；完成后压缩前一天的备份；
function do_increment() {
    echo "[+] `date` +------------------------Start--------------------+"
    innobackupex --incremental ${s_args} ${d_bak_tmp}
    echo "[-] `date` +------------------------cleanup------------------+"
    do_tar_yesterday
    echo "[-] `date` +------------------------The End------------------+"
}

###################### 全备份，未压缩；完成后，压缩这个备份；
function do_full_tar() {
    echo "[+] `date` +------------------------Start--------------------+"
    innobackupex ${s_args} ${d_bak_full}
    echo "[-] `date` +------------------------cleanup------------------+"
    do_tar
    echo "[-] `date` +------------------------The End------------------+"
}

###################### 全备份，边备份边压缩，stream=tar模式；
function do_full_stream() {
    echo "[+] `date` +------------------------Start--------------------+"
    innobackupex --stream=tar ${s_args} ${d_bak_full} |gzip >${f_bak_stream}
    echo "[-] `date` +------------------------cleanup------------------+"
    do_cleanup
    echo "[-] `date` +------------------------The End------------------+"
}



#################### 
case ${s_action} in
    full)
        do_full >"${d_bak_log}/$(date +%F_%H-%M-%S).log" 2>&1
        ;;
    incr)
        do_increment >"${d_bak_log}/$(date +%F_%H-%M-%S).log" 2>&1
        ;;
    full_tar)
        do_full_tar >"${d_bak_log}/$(date +%F_%H-%M-%S).log" 2>&1
        ;;
    full_stream)
        do_full_stream >"${d_bak_log}/$(date +%F_%H-%M-%S).log" 2>&1
        ;;
    *)
        usage
        ;;
esac
