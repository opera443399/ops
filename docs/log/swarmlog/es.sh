#!/bin/bash
#
# 2018/7/25

test $(docker ps -a -f name=logs-elasticsearch -q |wc -l) -eq 0 || \
docker rm -f $(docker ps -a -f name=logs-elasticsearch -q)

# ports: 9200[elasticsearch]
docker run -d -p "9200:9200" \
    --name logs-elasticsearch \
    -v /etc/localtime:/etc/localtime \
    -v /etc/timezone:/etc/timezone \
    -v /data/server/swarmlog/es:/usr/share/elasticsearch/data \
    -e "http.host=0.0.0.0" \
    -e "transport.host=localhost" \
    -e "network.host=0.0.0.0" \
    -e "xpack.security.enabled=false" \
    -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
    -e "bootstrap.memory_lock=true" \
    elasticsearch:5.6.10
