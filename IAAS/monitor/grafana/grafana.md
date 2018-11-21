# grafana
2018/4/23

### deploy

```bash
~]# cat start.sh
#!/bin/bash
#
# 2018/4/23

test $(docker ps -a -f name=monitor_grafana -q |wc -l) -eq 0 || \
docker rm -f $(docker ps -a -f name=monitor_grafana -q)

docker run -d -p 3000:3000 \
    --name monitor_grafana \
    -v /data/server/grafana/data:/var/lib/grafana \
    -e "GF_SECURITY_ADMIN_USER=${ADMIN_USER:-admin}" \
    -e "GF_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}" \
    grafana/grafana

```
