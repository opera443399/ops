#!/bin/bash
#
#2016/9/20
# crontab:
# */2 * * * * /usr/local/bin/test_www_by_curl.sh >>/tmp/test_www_by_curl.log 2>&1 &
echo "[S] at: `date`"
tag="$(echo `hostname` |awk -F'-' '{print $NF}')"
do_curl(){
    www=$1
    rnd=$2
    #PUT
    curl -H "Content-Type: application/xml" -d "{"name": "Jack A"}" "http://${www}/from_${tag}"
    curl -H "Content-Type: application/json" -d "{"name": "Jack B"}" "http://${www}/from_${tag}"
    curl -H "Content-Type: application/png" -d "{"img_path": "images/$(date +%F)/${rnd}.png"}" "http://${www}/from_${tag}"
    #GET
    curl -H "Content-Type: text/html; charset=UTF-8" --referer "www.${tag}.com/this_is_referer" "http://${www}/"
    curl -H "Content-Type: text/html; charset=UTF-8" --referer "www.${tag}.com/this_is_referer" "http://${www}/a/b/c.html?key=${tag}"
    curl -H "Content-Type: text/html; charset=GBK" --referer "www.${tag}.com/this_is_referer" "http://${www}/action.do?event=login&user=${tag}&sid=${rnd}"
    #
}
for i in `seq 1 2000`; do
    do_curl www.work.com "`od /dev/urandom -w12 -tx4 -An |sed -e 's/ //g' |head -n 1`"
    do_curl www.test.com "`od /dev/urandom -w12 -tx4 -An |sed -e 's/ //g' |head -n 1`"
done >/dev/null 2>&1
echo "[D] at: `date`"
