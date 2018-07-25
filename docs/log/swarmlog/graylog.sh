#!/bin/bash
#
# 2018/7/25

GRAYLOG_PASSWORD_SECRET='graylog-password-secret' \
GRAYLOG_ROOT_PASSWORD_SHA2='8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918' \
GRAYLOG_WEB_ENDPOINT_URI='http://10.50.200.101:9000/api' \
docker stack deploy -c docker-compose.yml logs
