#!/bin/bash
#
#v0.1: get info from jjs
set -e

this_url='https://shenzhen.leyoujia.com/esf/a1q9'
this_args='/?m=3&p=259&r=2'
f_prefix='jjs_'
f_default='jjs_1'
result='report.html'

function do_view(){
    cat $1 |grep -E '(/esf/detail/.*</a>|salePrice|㎡</span>|/xq/detail/.*</a>)' \
           |sed -r -e 's#\t##g' -e '/<meta/d' -e '/<input/d' -e 's#<em.*></em>##g' \
                   -e 's#<span class.*>(.*)</span>#\1#g' \
                   -e 's#<p.*>(.*)</p>#\1#g' \
                   -e 's#<span>(.*)</span>#\1#g' \
                   -e '/<a href="\/esf/i</li><li>'

}

function do_down(){
    curl -s -o $1 "${this_url}${this_args}"
}

do_down ${f_default}
page_total=$(grep '尾页' ${f_default} >/dev/null && echo $(grep '尾页' ${f_default} |awk '{print $3}' |cut -d'"' -f2) || echo 1)

echo "view page: 1"
do_view ${f_default} >${result}

if [ ${page_total} -gt 1 ]; then
    for i in `seq 2 ${page_total}`; do
        echo "view page: $i"
        this_page="${f_prefix}$i"
        do_down ${this_page}
        do_view ${this_page} >>${result}
    done
fi

echo '</li>' >>${result}

