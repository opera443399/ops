#!/bin/bash
# 
# 2015/11/11

/usr/bin/sendEmail -o message-charset="UTF-8" \
-s smtp.company.com \
-xu test@company.com \
-xp xxx \
-f test@company.com \
-t "$1" \
-u "$2" \
-m "$3"

