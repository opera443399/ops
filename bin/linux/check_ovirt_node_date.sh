#!/bin/bash
# 
# pc
# 2016/1/19

function do_record(){
    echo '-----------------------------' >>/tmp/ovirt/record.log
    echo "[passed] `cat /tmp/ovirt/test_node_date.log |grep CST |head -n 1`" >>/tmp/ovirt/record.log
}

function do_alert(){
    mail_bin="/usr/bin/sendEmail -s smtp.test.com \
                    -xu abc@test.com \
                    -xp xxxxxx \
                    -f abc@test.com \
                    -o message-charset=utf-8"
    to="admin@test.com"

    subject="ovirt node datetime inconsistency."
    body="from ${HOSTNAME}: $0"
    ${mail_bin} -t ${to} -u ${subject} -m ${body} -a '/tmp/ovirt/test_node_date.log'
}

function do_check(){
    [ -d '/tmp/ovirt' ] || mkdir -p /tmp/ovirt
    salt '*.ovirt.node' cmd.run 'date' --no-color --output-file='/tmp/ovirt/test_node_date.log'
    dt=`cat /tmp/ovirt/test_node_date.log |grep CST |head -n 1 |awk '{print $4}'`
    cnt=`grep -c "$dt" /tmp/ovirt/test_node_date.log`
    test $cnt -eq 4 && do_record || do_alert
}

function help(){
    cat <<'_EOF'
USAGE: 

1. generate logrotate config file
~]# cat /tmp/ovirt/check_ovirt_logrotate.conf
/tmp/ovirt/record.log
{
compress
copytruncate
daily
dateext
missingok
notifempty
rotate 2
}

2. edit crontab
~]# crontab -l |grep logrotate
*/10 * * * *  /usr/local/bin/check_ovirt_node_date.sh check >/dev/null 2>&1 &
59 23 * * * /usr/sbin/logrotate -f /tmp/ovirt/check_ovirt_logrotate.conf'

_EOF
}

case $1 in
    check)
        do_check
        ;;
    *)
        help
        ;;
esac
