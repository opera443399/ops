#!/bin/bash
#
#2016/7/26

do_rewrite() {
    ff=$1
    echo "[*] Convert -> ${ff}"
    wget -q http://www.zanghaihuawang.com/laojiumen/${ff}.html -O old/${ff}.html
    grep 'h2' old/${ff}.html >/dev/null
    if [ $? -eq 1 ]; then
        echo '[E] empty file.'
        exit 1
    else
        cat <<'_EOF' >new/${ff}.html
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
</head>
<body>
_EOF
        sed -n '/<h2>/,/\[Enter\]/p' old/${ff}.html |sed 's/\/laojiumen\///' >>new/${ff}.html
        cat <<'_EOF' >>new/${ff}.html
</body>
</html>
_EOF
        f_next=$(cat new/${ff}.html |grep 'pager_next' |grep -Eo '[0-9]+')
        if [ -z ${f_next} ]; then
            echo '[E] next file not found.'
            exit 2
	else
            do_rewrite ${f_next}
        fi
    fi
}

do_gb2312_to_utf8() {
    #yum -y groupinstall "Development Tools" && wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz && tar zxvf libiconv-1.14.tar.gz && cd libiconv-1.14 && ./configure && make && make install
    for i in `ls new/`; do iconv -c -f gb2312 -t utf-8 test/$i >new_utf8/$i;done
}

mkdir -p old new
do_rewrite $1
