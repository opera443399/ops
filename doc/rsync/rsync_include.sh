#!/bin/bash
#
# 2015/4/8
#rsync  -avzP  --exclude "log" --exclude "upload" root@192.168.1.222::web /home/web/

rsync -avzP --include-from="/home/ops/conf/include_from_222_web.conf" --exclude="/*" root@192.168.1.222::web /home/web/

cat <<_FILES
---------------
$ files in: include_from_222_web.conf
app
config
doc
library
service
task
templates_c
tmp_cache
www
_FILES
