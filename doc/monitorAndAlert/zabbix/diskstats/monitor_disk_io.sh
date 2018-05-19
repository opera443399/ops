#!/bin/bash
#
# 2017/3/3
# PC
# ver1.0.5
#echo "[`date`] $1 $2 $3" >>/tmp/test.log

##
usage(){
    cat <<_EOF

usage:  $0  [disk_lld]
        $0  [get] [reads||read_merges|read_sectors|read_ticks] disk_name
        $0  [get] [writes||write_merges|write_sectors|write_ticks] disk_name
        $0  [get] [in_flight|io_ticks|time_in_queue] disk_name


[reference]
1. http://hustcat.github.io/iostats/

_EOF


    cat <<'_EOF'

[zabbix-agent-conf]
~]# cat <<'_ABC' >/etc/zabbix/zabbix_agentd.d/userparameter_diskstats.conf
## lld
UserParameter=diskstats.disk.discovery[*], /bin/bash /etc/zabbix/scripts/monitor_disk_io.sh lld
## diskstats
UserParameter=diskstats.get[*], /bin/bash /etc/zabbix/scripts/monitor_disk_io.sh get $1 $2
_ABC

_EOF



}



###### disk lld ######

disk_lld_pre(){
    local d=`lsblk -o NAME,TYPE |awk '$2=="disk"{print $1}'`
    for i in $d
    do
        echo -e '\t\t{'
        echo -e "\t\t\t\"{#DISK_NAME}\": \"$i\""
        echo -e '\t\t},'
    done
}

disk_lld(){
    echo -e '{'
    echo -e '\t"data": ['
    disk_lld_pre |sed '$d'
    echo -e '\t\t}'
    echo -e '\t]'
    echo -e '}'
}


#read
disk_reads(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $4}'
}

disk_read_merges(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $5}'
}

disk_read_sectors(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $6}'
}

disk_read_ticks(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $7}'
}

#write
disk_writes(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $8}'
}

disk_write_merges(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $9}'
}

disk_write_sectors(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $10}'
}

disk_write_ticks(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $11}'
}

#others
disk_in_flight(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $12}'
}

disk_io_ticks(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $13}'
}

disk_time_in_queue(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $14}'
}

##
case $1 in
    lld)
        disk_$1
        ;;
    get)
        disk_$2 $3
        ;;
    *)
        usage
        ;;
esac

