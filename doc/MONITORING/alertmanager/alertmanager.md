# alertmanager
2018/5/2


### deploy

```bash
~]# cat start.sh
#!/bin/bash
#
# 2018/5/2

test $(docker ps -a -f name=monitor_alertmanager -q |wc -l) -eq 0 || \
docker rm -f $(docker ps -a -f name=monitor_alertmanager -q)

docker run -d -p '127.0.0.1:9093:9093' \
    --name monitor_alertmanager \
    -v /data/server/alertmanager/data:/alertmanager \
    -v /data/server/alertmanager/conf/alertmanager.yml:/etc/alertmanager/config.yml \
    -v /data/server/alertmanager/templates:/etc/alertmanager/templates \
    prom/alertmanager:v0.14.0


```
