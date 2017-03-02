#!/bin/bash
#
# 2017/3/2
# PC
#echo "[`date`] $1 $2 $3" >>/tmp/test.log

##
usage(){
    cat <<_EOF

usage:  $0  [disk_lld]
        $0  [get] [read_ops|read_sectors|read_ms] disk_name
        $0  [get] [write_ops|write_sectors|write_ms] disk_name
        $0  [get] [io_active|io_ms] disk_name

_EOF


    cat <<'_EOF'
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
    local d=`lsblk -o NAME,TYPE |grep disk |awk '{print $1}'`
    for i in $d
    do
        printf '\t\t{\n'
        echo -e "\t\t\t\"{#DISK_NAME}\": \"$i\""
        printf '\t\t},\n'
    done
}

disk_lld(){
    printf '{\n'
    printf '\t"data": [\n'
    disk_lld_pre |sed '$d'
    printf '\t\t}\n'
    printf '\t]\n'
    printf '}\n'
}


disk_read_ops(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $4}'
}

disk_read_sectors(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $6}'
}

disk_read_ms(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $7}'
}

disk_write_ops(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $8}'
}

disk_write_sectors(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $10}'
}

disk_write_ms(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $11}'
}

disk_io_active(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $12}'
}

disk_io_ms(){
    cat /proc/diskstats |grep $1 |head -n1 |awk '{print $13}'
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

