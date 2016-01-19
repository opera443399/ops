#!/bin/bash
# 
# 2016/1/19

n=0
for i in 1 2 3
do
    /usr/bin/ldapsearch -h ldap.test.com  -D "companyname\tester01" -w 123456 -b 'CN=tester01,OU=companyname,OU=Users & Workstations,DC=companyname,DC=com' >/dev/null 2>&1
    if [ $? -ne 0 ];then
        n=$(($n+1))
    fi
    sleep .2
done
echo $n
