#!/bin/bash
#
# 2018/7/25

test $(docker ps -a -f name=logs-mongodb -q |wc -l) -eq 0 || \
docker rm -f $(docker ps -a -f name=logs-mongodb -q)

# ports: 9200[mongodb]
docker run -d -p "27017:27017" \
    --name logs-mongodb \
    -v /etc/localtime:/etc/localtime \
    -v /etc/timezone:/etc/timezone \
    -v /data/server/swarmlog/mongodb:/usr/share/elasticsearch/data \
    mongo:3
