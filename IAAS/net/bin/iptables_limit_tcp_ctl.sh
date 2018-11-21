#!/bin/bash
#
# limit port 80 download speed.

ACTION=$1
n_port=80
# n_limit * 15/100 KB, 100Mbit/s = 10MB/s = 10 * 1000 KB/s
n_limit=$2
[ ! -z $n_limit ] || n_limit=3000
n_limit_burst=$3
[ ! -z $n_limit_burst ] || n_limit_burst=3000

function add(){
    iptables -A OUTPUT -p tcp -m tcp --sport $n_port -m limit --limit $n_limit/sec --limit-burst $n_limit_burst -j ACCEPT 
    iptables -A OUTPUT -p tcp -m tcp --sport $n_port -j DROP    
    service iptables save
}

function del(){
    iptables -D OUTPUT -p tcp -m tcp --sport $n_port -m limit --limit $n_limit/sec --limit-burst $n_limit_burst -j ACCEPT 
    iptables -D OUTPUT -p tcp -m tcp --sport $n_port -j DROP    
    service iptables save
}

function cls() {
    iptables -F OUTPUT  
    service iptables save
}

function stat() {
    iptables -L -n |sed -n '/OUTPUT/,$p'
}

ACTION=$1

case ${ACTION} in
    add)
        add
        stat
        ;;
    del)
        del
        stat
        ;;
    clear)
        cls
        stat
        ;;
    new)
        cls
        add
        stat
        ;;
    status)
        stat
        ;;
    *)
        cat <<_START
Usage: 
    $0 [add|del|new|clear|status] limit limit_burst 
    [default setting: limit=$n_limit, limit_burst=$n_limit_burst]
eg:
    $0 add              add a rule to OUTPUT Chain. [default]
    $0 del              delete a rule from OUTPUT Chain. [default]
    $0 new              clear->add.
    $0 clear            delete all rules in OUTPUT Chain.
    $0 status           show iptables OUTPUT Chain.
    $0 add 2500 3000    add a rule to OUTPUT Chain.

_START
        ;;
esac
