#!/bin/bash
#
# 2018/7/25

sysctl -w vm.max_map_count=262144

test $(docker ps -a -f name=logs-elasticsearch -q |wc -l) -eq 0 || \
docker rm -f $(docker ps -a -f name=logs-elasticsearch -q)

# ports: 9200[elasticsearch]
docker run -d -p "9200:9200" \
    --ulimit memlock=-1:-1 \
    --name logs-elasticsearch \
    -v /etc/localtime:/etc/localtime \
    -v /etc/timezone:/etc/timezone \
    -v /data/server/swarmlog/es:/usr/share/elasticsearch/data \
    -e "cluster.name=docker-logs-cluster" \
    -e "bootstrap.memory_lock=true" \
    -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
    -e "http.host=0.0.0.0" \
    -e "transport.host=0.0.0.0" \
    -e "network.host=0.0.0.0" \
    -e "xpack.security.enabled=false" \
    elasticsearch:5.6.10
