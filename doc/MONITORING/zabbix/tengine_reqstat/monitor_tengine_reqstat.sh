#!/bin/bash
#
# 2017/2/22
# PC
#echo "[`date`] $1 $2 $3" >>/tmp/test.log

curl_opts='-s http://127.0.0.1:80/rstatus'

##
usage(){
    cat <<_EOF

usage:  $0  [hosts|hosts_lld]
        $0  [get] field

[reqstat field]
bytes_in 从客户端接收流量总和
bytes_out 发送到客户端流量总和
conn_total 处理过的连接总数
req_total 处理过的总请求数
http_2xx 2xx请求的总数
http_3xx 3xx请求的总数
http_4xx 4xx请求的总数
http_5xx 5xx请求的总数
http_other_status 其他请求的总数
rt rt的总数
ups_req 需要访问upstream的请求总数
ups_rt 访问upstream的总rt
ups_tries upstream总访问次数
http_200 200请求的总数
http_206 206请求的总数
http_302 302请求的总数
http_304 304请求的总数
http_403 403请求的总数
http_404 404请求的总数
http_416 416请求的总数
http_499 499请求的总数
http_500 500请求的总数
http_502 502请求的总数
http_503 503请求的总数
http_504 504请求的总数
http_508 508请求的总数
http_other_detail_status 非以上13种status code的请求总数
http_ups_4xx upstream返回4xx响应的请求总数
http_ups_5xx upstream返回5xx响应的请求总数

_EOF
}


###### rstat details ######
rstat_get_bytes_in(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $3}'
}

rstat_get_bytes_out(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $4}'
}

rstat_get_conn_total(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $5}'
}

rstat_get_req_total(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $6}'
}

rstat_get_http_2xx(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $7}'
}

rstat_get_http_3xx(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $8}'
}

rstat_get_http_4xx(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $9}'
}

rstat_get_http_5xx(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $10}'
}

rstat_get_http_other_status(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $11}'
}

rstat_get_rt(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $12}'
}

rstat_get_ups_req(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $13}'
}

rstat_get_ups_rt(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $14}'
}

rstat_get_ups_tries(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $15}'
}

rstat_get_http_200(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $16}'
}

rstat_get_http_206(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $17}'
}

rstat_get_http_302(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $18}'
}

rstat_get_http_304(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $19}'
}

rstat_get_http_403(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $20}'
}

rstat_get_http_404(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $21}'
}

rstat_get_http_416(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $22}'
}

rstat_get_http_499(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $23}'
}

rstat_get_http_500(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $24}'
}

rstat_get_http_502(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $25}'
}

rstat_get_http_503(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $26}'
}

rstat_get_http_504(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $27}'
}

rstat_get_http_508(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $28}'
}

rstat_get_http_other_detail_status(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $29}'
}

rstat_get_http_ups_4xx(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $30}'
}

rstat_get_http_ups_5xx(){
    curl ${curl_opts} |grep "$1" |awk -F',' '{print $31}'
}



###### rstat lld ######

rstat_hosts(){
    curl ${curl_opts} |awk -F',' '{print $1","$2}' |sort 
}

rstat_hosts_lld_pre(){
    local buckets=`rstat_hosts`
    for i in $buckets
    do
        printf '\t\t{\n'
        echo -e "\t\t\t\"{#RSTAT_KEY}\": \"$i\""
        printf '\t\t},\n'
    done
}

rstat_hosts_lld(){
    printf '{\n'
    printf '\t"data": [\n'
    rstat_hosts_lld_pre |sed '$d'
    printf '\t\t}\n'
    printf '\t]\n'
    printf '}\n'
}

##
case $1 in
    hosts|hosts_lld)
        rstat_$1
        ;;
    get)
        rstat_$1_$3 $2
        ;;
    *)
        usage
        ;;
esac
