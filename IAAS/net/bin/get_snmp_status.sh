#!/bin/bash
#
# 2015/12/21

function do_check() {
    echo "[+] `date '+%F %T'` GET SNMP STATUS FROM: $1"
    /usr/bin/snmpwalk -v 2c -c public $1 1.3.6.1.4.1.674.10892.2.2.1.0
    retval=$?
    if [ ${retval} -eq 1 ]; then
        ping -c 10 $1
        nmap -p 161 -sU $1
    fi
    echo "[-] `date '+%F %T'` DONE!"
}

function do_clean() {
    dt_old=$(date -d '-1 days' +%F)
    retval=`grep "${dt_old} 23:59" $1 |wc -l`
    if [ ${retval} -eq 2 ]; then
        echo "[+] `date '+%F %T'` Clean.">$1
    fi
}

do_clean /tmp/get_snmp_status.log
do_check 10.50.200.101 >>/tmp/get_snmp_status.log 2>&1
