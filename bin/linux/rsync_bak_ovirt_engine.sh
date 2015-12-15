#!/bin/bash
#
# ovirt engine backup
# 2015/12/14 

d_bak_root="/tmp/ovirt_engine_backup"
d_bak="${d_bak_root}/`date +%Y%m%d_%H%M%S`"
f_log="/tmp/rsync_ovirt_bak.txt"

function do_rsync() {
    echo "[3] `date` [INFO] 归档到外部存储。"
    rsync -avP --password-file=/etc/rsync.pass $1 backup@10.50.200.93::bak_ovirt_engine
    echo "[3] `date` [INFO] step 3 完成。"
}


function do_clean() {
    echo "[2] `date` [INFO] 清理3天前的备份。"
    find ${d_bak_root} -mtime +3 -print
    find ${d_bak_root} -mtime +3 -delete
    echo "[2] `date` [INFO] step 2 完成。"
}


function do_bak() {
    echo "[1] `date` [INFO] 开始备份。"
    [ -d ${d_bak} ] || mkdir -pv ${d_bak}
    cd ${d_bak}
    engine-backup --mode=backup --file=ovirt-engine.bak --log=backup.log
    echo "[1] `date` [INFO] step 1 完成。"
    do_clean
    do_rsync ${d_bak_root}/
}


function do_alert() {
    do_bak >${f_log} 2>&1
    if [ $? -eq 0 ];then
        status="OK" 
    else
        status="Failed"
    fi

    mail_bin="sendEmail -s smtp.xxx.com \
                        -xu f@xxx.com \
                        -xp xxx \
                        -f f@xxx.com \
                        -o message-charset=utf-8"
    to="me@xxx.com"
    subject="sz ovirt engine backup ${status}" 
    body="from ${HOSTNAME}: $0"
    ${mail_bin} -t ${to} -u ${subject} -m ${body} -a ${f_log}
}

do_alert
