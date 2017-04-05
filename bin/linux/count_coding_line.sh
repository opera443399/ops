#!/bin/bash
# 
# 2017/4/5
# pc
# a simple example for howto count your coding lines 

dest_dir=$1
cd ${dest_dir}
echo -e "\n\033[1;34m--Count your coding lines from dir: ${dest_dir}--\033[0m"

echo -en '\n\033[1;33m-python: \033[0m'
r1=`find . -name "*.py" |xargs -i grep -v "^$" {} |wc -l`
echo $r1

echo -en '\n\033[1;33m-html: \033[0m'
r2=`find . -name "*.html" |xargs -i grep -v "^$" {} |wc -l`
echo $r2

echo -en '\n\033[1;33m-js: \033[0m'
r3=`find . -name "*.js" |grep -vE "bootstrap|npm|jquery|admin|rest_framework" |xargs -i grep -v "^$" {} |wc -l`
echo $r3

echo -en '\n\033[1;33m-css: \033[0m'
r4=`find . -name "*.css" |grep -vE "bootstrap|jquery|admin|rest_framework" |xargs -i grep -v "^$" {} |wc -l`
echo $r4

echo -en '\n\033[1;33m-json: \033[0m'
r5=`find . -name "*.json" |grep -vE "bootstrap|jquery|admin|rest_framework" |xargs -i grep -v "^$" {} |wc -l`
echo $r5

echo -en '\n\033[1;33m-csv: \033[0m'
r6=`find . -name "*.csv" |grep -vE "bootstrap|jquery|admin|rest_framework" |xargs -i grep -v "^$" {} |wc -l`
echo $r6

echo -en '\n\033[1;33m-i18n: \033[0m'
r7=`find . -name "*.po" |grep -vE "bootstrap|jquery|admin|rest_framework" |xargs -i grep -v "^$" {} |wc -l`
echo $r7


echo -en '\n\033[1;33m==all==: \033[0m'
echo $((r1+r2+r3+r4+r5+r6+r7))

echo -e "\n\033[1;34m--The End.--\033[0m"

