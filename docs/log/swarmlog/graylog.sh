#!/bin/bash
#
# 2018/7/25

# ports: 514[Syslog], 12201[GELF], 9000[Graylog web]
# GRAYLOG_PASSWORD_SECRET: `chars > 16`
# GRAYLOG_ROOT_PASSWORD_SHA2: `$ echo -n admin | sha256sum`


test $(docker ps -a -f name=logs-graylog -q |wc -l) -eq 0 || \
docker rm -f $(docker ps -a -f name=logs-graylog -q)

docker run -d -p "9000:9000" -p "514:514" -p "514:514/udp" -p "12201:12201" -p "12201:12201/udp" \
    --name logs-graylog \
    -v /etc/localtime:/etc/localtime \
    -v /etc/timezone:/etc/timezone \
    -v /data/server/swarmlog/graylog:/usr/share/graylog/data/journal \
    -e "GRAYLOG_PASSWORD_SECRET=your-password-secret-here" \
    -e "GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918" \
    -e "GRAYLOG_WEB_ENDPOINT_URI=http://10.50.200.101:9000/api" \
    -e "GRAYLOG_MONGODB_URI=mongodb://10.50.200.101/graylog" \
    -e "GRAYLOG_ELASTICSEARCH_HOSTS=http://10.50.200.101:9200" \
    -e "GRAYLOG_ROOT_TIMEZONE=Asia/Shanghai" \
    graylog/graylog:2.4.6-1
