#!/bin/bash
#
# 2017/3/23
# PC
# ver1.0.0


f_domain=$1
f_dns=$2
#f_dns="119.29.29.29"

n=0
for i in 1 2 3
do
    ret=`nslookup ${f_domain} ${f_dns} -timeout=3 |grep -A 1 'Name' |wc -l`
    [ $ret -gt 0 ] || n=$(($n+1))
    sleep .2
done
echo $n
