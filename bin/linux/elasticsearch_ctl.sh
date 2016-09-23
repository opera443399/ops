#!/bin/bash
#
#2016/9/23

show_h(){
    echo -e '\033[32m[+] show health\033[0m'
    echo -e '\033[32m-----------------------------------------------------------\033[0m'
    curl 'localhost:9200/_cat/health?v'
}

show_n(){
    echo -e '\033[32m[+] show nodes\033[0m'
    echo -e '\033[32m-----------------------------------------------------------\033[0m'
    curl 'localhost:9200/_cat/nodes?v'
}

show_i(){
    echo -e '\033[32m[+] show indices\033[0m'
    echo -e '\033[32m-----------------------------------------------------------\033[0m'
    curl 'localhost:9200/_cat/indices?v'
}

index_del(){
    #curl -XDELETE 'http://localhost:9200/filebeat-*?pretty'
    echo -e "\033[32m[+] delete index: ${1}\033[0m"
    echo -e '\033[32m-----------------------------------------------------------\033[0m'
    curl -XDELETE "http://localhost:9200/${1}*?pretty"
}

show_t(){
    #curl 'http://localhost:9200/_template/filebeat?pretty'
    echo -e "\033[32m[+] show template for index: ${1}\033[0m"
    echo -e '\033[32m-----------------------------------------------------------\033[0m'
    curl 'http://localhost:9200/_template/${1}?pretty'
}

tpl_set(){
    #curl -XPUT 'http://localhost:9200/_template/filebeat?pretty' -d@/tmp/elasticsearch.template.filebeat.json
    echo -e "\033[32m[+] set template for index: ${1}\033[0m"
    echo -e '\033[32m-----------------------------------------------------------\033[0m'
    curl -XPUT 'http://localhost:9200/_template/${1}?pretty' -d@${2}
}


usage(){
    cat <<_EOF

control elasticsearch.

Usage:  $0 [h|n|ishow|idel|tshow|tset]
    $0 h                                        : show es cluster health
    $0 n                                        : list es nodes
    $0 i                                        : list es indices
    $0 idel index-name                          : del index as given
    $0 t template-name                          : show template as given
    $0 tset template-name template-file-path    : set user-define template


_EOF
}


case $1 in
    h|n|i|t)
        show_$1
        ;;
    idel)
        index_del $2
        ;;
    tset)
        tpl_set $2 $3
        ;;
    *)
        usage
        exit 1
esac
