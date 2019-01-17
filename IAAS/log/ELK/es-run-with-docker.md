# es run with docker

2019/1/17


just a demo

```bash
sysctl -w vm.max_map_count=262144

mkdir -p /data/es
chown -R 1000:1000 /data/es

# es port: 9200
docker run -d \
  --name logs-es \
  -v /etc/localtime:/etc/localtime \
  -v /data/es:/usr/share/elasticsearch/data \
  --cpus "2.0" \
  --memory "2048m" \
  -e "cluster.name=docker-logs-cluster" \
  -e "bootstrap.memory_lock=true" \
  -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
  -e "xpack.security.enabled=false" \
  --ulimit memlock=-1:-1 \
  opera443399/elasticsearch:6.5.2

sleep 1s
docker logs --tail 100 --since 5m -f logs-es

```
