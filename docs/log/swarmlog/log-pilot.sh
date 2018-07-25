#!/bin/bash
#
# 2018/7/25

docker rm -f log-pilot
docker run -d --rm -it \
    --name log-pilot \
    -v /etc/localtime:/etc/localtime \
    -v /etc/timezone:/etc/timezone \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /:/host \
    --privileged \
    -e PILOT_TYPE="fluentd" \
    -e FLUENTD_OUTPUT="graylog" \
    -e GRAYLOG_HOST="10.50.200.101" \
    -e GRAYLOG_PORT="12201" \
    registry.cn-hangzhou.aliyuncs.com/acs-sample/log-pilot:latest
