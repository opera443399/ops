#!/bin/bash
#
# 2017/3/16
# PC
# ver1.0.0
#echo "[`date`] $1 $2 $3" >>/tmp/test.log

f_ip_port_list='/etc/zabbix/scripts/monitor_ip_port.conf'

##
usage(){
    cat <<_EOF

usage:  $0  [lld]
        $0  [get] [ip:port] [app_name]

_EOF


    cat <<'_EOF'

[zabbix-agent-conf]
~]# cat <<'_ABC' >/etc/zabbix/zabbix_agentd.d/userparameter_ip_port.conf
## lld
UserParameter=ip.port.discovery[*], /bin/bash /etc/zabbix/scripts/monitor_ip_port.sh lld
## tcp listen status
UserParameter=ip.port.get[*], /bin/bash /etc/zabbix/scripts/monitor_ip_port.sh get $1 $2
_ABC


[monitor_ip_port.conf]
#format:
ip:port,app

#exp:
line1-> 127.0.0.1:11211,memcached
line2-> :11211,memcached

_EOF



}



###### tcp listen lld ######

ip_port_lld_pre(){
    local d=`cat ${f_ip_port_list}`
    for i in $d
    do
        ip_port=`echo $i |awk -F"," '{print $1}'`
        app_name=`echo $i |awk -F"," '{print $2}'`
        echo -e '\t\t{'
        echo -e "\t\t\t\"{#TCP_IP_PORT}\": \"${ip_port}\","
        echo -e "\t\t\t\"{#TCP_APP_NAME}\": \"${app_name}\""
        echo -e '\t\t},'
    done
}

ip_port_lld(){
    echo -e '{'
    echo -e '\t"data": ['
    ip_port_lld_pre |sed '$d'
    echo -e '\t\t}'
    echo -e '\t]'
    echo -e '}'
}


#read
ip_port_get(){
    ip_port=$1
    app_name=$2
    ss -antl src ${ip_port} |grep -v '^State' |wc -l
}


##
case $1 in
    lld)
        [ -f ${f_ip_port_list} ] || exit
        ip_port_$1
        ;;
    get)
        ip_port_get $2 $3
        ;;
    *)
        usage
        ;;
esac

