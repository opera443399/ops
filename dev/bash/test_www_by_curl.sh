#!/bin/bash
#
#2016/9/21
# crontab:
# */2 * * * * /usr/local/bin/test_www_by_curl.sh >>/tmp/test_www_by_curl.log 2>&1 &
echo "[S] at: `date`"
tag="$(echo `hostname` |awk -F'-' '{print $NF}')"

m_1(){
    curl -s -H "Content-Type: application/xml" -d "{"name": "Jack A"}" "http://${www}/from_${tag}"
}
m_2(){
    curl -s -H "Content-Type: application/json" -d "{"name": "Jack B"}" "http://${www}/from_${tag}"
}
m_3(){
    curl -s -H "Content-Type: text/html; charset=UTF-8" --referer "www.${tag}.com/from_${rnd}" "http://${www}/"
}
m_4(){
    curl -s -H "Content-Type: text/html; charset=UTF-8" --referer "www.${tag}.com/this_is_referer" "http://${www}/"
}
m_5(){
    curl -s -H "Content-Type: text/html; charset=UTF-8" --referer "www.${tag}.com/this_is_referer" "http://${www}/a/b/c.html?key=${tag}"
}
m_6(){
    curl -s -H "Content-Type: text/html; charset=UTF-8" --referer "www.${tag}.com/from_${rnd}" "http://${www}/"
}
m_7(){
    curl -s -H "Content-Type: application/png" -d "{"img_path": "images/$(date +%F)/${rnd}.png"}" "http://${www}/from_${tag}"
}
m_8(){
    curl -s -H "Content-Type: text/html; charset=GBK" --referer "www.${tag}.com/this_is_referer" "http://${www}/action.do?event=login&user=${tag}&sid=${rnd}"
}
m_9(){
    curl -s -H "Content-Type: text/html; charset=UTF-8" --referer "www.${tag}.com/from_${rnd}" "http://${www}/"
}

do_curl(){
    www=$1
    rnd=$2
    n=$(cat /dev/urandom |head -n 11 |cksum |head -c1)
    #echo $n
    m_$n >/dev/null 2>&1
}
for i in `seq 1 1000`; do
    do_curl www.work.com "`od /dev/urandom -w12 -tx4 -An |sed -e 's/ //g' |head -n 1`"
    do_curl www.test.com "`od /dev/urandom -w12 -tx4 -An |sed -e 's/ //g' |head -n 1`"
done 
echo "[D] at: `date`"
