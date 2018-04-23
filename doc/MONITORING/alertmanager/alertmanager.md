# alertmanager
2018/4/23


### deploy

```bash
~]# cat start.sh
#!/bin/bash
#
# 2018/4/23

test $(docker ps -a -f name=monitor_alertmanager -q |wc -l) -eq 0 || \
docker rm -f $(docker ps -a -f name=monitor_alertmanager -q)
docker run -d -p 9093:9093 \
    --name monitor_alertmanager \
    -v /data/server/alertmanager/data:/alertmanager \
    -e "API_SECRET=xxx" \
    -e "CORP_ID=xxx" \
    -e "AGENT_ID=111" \
    -e "TO_PARTY=111" \
    opera443399/swarmprom-alertmanager:v0.14.0 \
      --config.file=/etc/alertmanager/alertmanager.yml \
      --storage.path=/alertmanager

```
