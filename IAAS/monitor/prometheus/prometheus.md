# prometheus
2018/4/23

### deploy

```bash
~]# cat start.sh
#!/bin/bash
#
# 2018/4/23

test $(docker ps -a -f name=monitor_prometheus -q |wc -l) -eq 0 || \
docker rm -f $(docker ps -a -f name=monitor_prometheus -q)

docker run -d -p 9090:9090 \
    --name monitor_prometheus \
    -v "$(pwd)"/config.yml:/etc/prometheus/prometheus.yml \
    -v "$(pwd)"/rules_docker_node.yml:/etc/prometheus/rules_docker_node.yml \
    prom/prometheus:v2.2.1 \
      --config.file=/etc/prometheus/prometheus.yml \
      --storage.tsdb.path=/prometheus \
      --storage.tsdb.retention=7d

```
