#!/bin/bash
#
# 2016/3/11
# via pc

d_bak_root="/data/backup/mysql"
d_bak="${d_bak_root}/`date +%F`"
f_bak_log="${d_bak}/dump.log"
[ -d ${d_bak} ] || mkdir -pv ${d_bak}

function do_dump() {
    cd ${d_bak}
    list_of_db=`mysql -h127.0.0.1 -P3306 -uroot --password=xxx -e 'show databases;' |grep -vE '(Database|information_schema|mysql|performance_schema|test)'` 
    # for i in $list_of_db;do echo $i;done

    echo "[1] `date` [INFO] run mysqldump:"
    for i in ${list_of_db};do
        echo "[--] db -> $i"
    	mysqldump -h127.0.0.1 -P3306 -uroot --password=xxx -R -E --triggers=true -B $i >$i.sql
    done
    echo "[1] run gzip:"
    gzip -v *.sql
    echo "[1] `date` [INFO] step 1 done."
}

function do_clean() {
    echo "[2] `date` [INFO] delete files over 7 days."
    find ${d_bak_root} -mtime +7 -print
    find ${d_bak_root} -mtime +7 -delete
    echo "[2] `date` [INFO] step 2 done."
}


function do_rsync() {
    echo "[3] `date` [INFO] rsync to: /mnt/backup/mysql"
    rsync -av ${d_bak_root}/ /mnt/backup/mysql/
    echo "[3] `date` [INFO] step 3 done."
}


function do_bak() {
    do_dump
    do_clean
    do_rsync
}


function do_alert() {
    do_bak >${f_bak_log} 2>&1
    if [ $? -eq 0 ];then
        retval="OK"
    else
        retval="Failed"
    fi

    mail_bin="sendEmail -s smtp.xxx.com \
                        -xu xxx \
                        -xp xxx \
                        -f xxx \
                        -o message-charset=utf-8"
    to="xxx"
    subject="backup db ${retval}"
    body="from ${HOSTNAME}: $0"
    ${mail_bin} -t ${to} -u ${subject} -m ${body} -a ${f_bak_log}
    echo ${retval}
}

do_alert
