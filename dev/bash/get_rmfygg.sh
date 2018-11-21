#!/bin/bash
#
# 2017/11/10

dt='2017-10-19'
i_start=90
i_end=105

mkdir -p src 
rm -f src/*.html


for cnt in `seq ${i_start} ${i_end}`; do
    curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36" http://rmfygg.court.gov.cn/psca/lgnot/bulletin/%E6%B7%B1%E5%9C%B3_0_${cnt}.html -o src/${cnt}.html
    grep ${dt} src/${cnt}.html && echo "[${cnt}] : found" || echo "[${cnt}]"
    sleep 1s
done

grep -B1 ${dt} src/*.html |grep -v ${dt} |sed -nr 's/(.*)<a (.*) target="_blank" (.*)<\/td>/<a \2\3\n/p' >src/result.html
head src/result.html
