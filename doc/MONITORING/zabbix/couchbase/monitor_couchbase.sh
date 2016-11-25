#!/bin/bash
#
#2016/11/25
#v1.2
#PC

cb_opts='-c 127.0.0.1:8091 -u Administrator -p xxx'
curl_opts='-s -u Administrator:xxx http://127.0.0.1:8091/pools/default/buckets'

##
usage(){
    cat <<_EOF

usage:  $0  [cluster_info|cluster_list|cluster_healthy]
        $0  [node_healthy|node_active]
        $0  [bucket_list|bucket_info|bucket_lld]

_EOF
}

###### cb cluster details ######
cb_cluster_info(){
    /opt/couchbase/bin/couchbase-cli server-info $cb_opts
}

cb_cluster_list(){
    /opt/couchbase/bin/couchbase-cli server-list $cb_opts
}

cb_cluster_healthy(){
    cb_cluster_list |grep -o 'healthy' |wc -l
}

###### cb current node status ######
cb_node_healthy(){
    local stat=`cb_cluster_info |jq '.status' |cut -d '"' -f2`
    if [ "X$stat" == "Xhealthy" ]; then echo 1; else echo 0;fi
}

cb_node_active(){
    local stat=`cb_cluster_info |jq '.clusterMembership' |cut -d '"' -f2`
    if [ "X$stat" == "Xactive" ]; then echo 1; else echo 0;fi
}

###### cb bucket details ######
cb_bucket_list(){
    /opt/couchbase/bin/couchbase-cli bucket-list $cb_opts |sed -E '/(bucketType|authType|saslPassword|proxyPort|numReplicas|ramQuota|ramUsed)/d'
}

cb_bucket_info(){
    # exp:
    # memUsed, dataUsed, diskUsed, itemCount, diskFetches, opsPerSec, quotaPercentUsed
    local bucket_name=$1
    curl $curl_opts/$bucket_name |jq ".basicStats.$2" |cut -d '"' -f2
}

cb_bucket_lld_pre(){
    local buckets=`cb_bucket_list`
    echo $buckets |grep -o 'ERROR' >/dev/null && exit 2
    for i in $buckets
    do
        printf '\t\t{\n'
        echo -e "\t\t\t\"{#BUCKETNAME}\": \"$i\""
        printf '\t\t},\n'
    done
}

cb_bucket_lld(){
    printf '{\n'
    printf '\t"data": [\n'
    cb_bucket_lld_pre |sed '$d'
    printf '\t\t}\n'
    printf '\t]\n'
    printf '}\n'
}

##
case $1 in
    cluster_info|cluster_list|cluster_healthy|node_healthy|node_active|bucket_list|bucket_info|bucket_lld)
        cb_$1 $2 $3
        ;;
    *)
        usage
        ;;
esac
