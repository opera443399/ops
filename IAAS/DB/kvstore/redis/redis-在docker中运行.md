# redis-在docker中运行
2018/11/23



### 部署
```bash
~]# mkdir -p /data/server/redis
~]# cd /data/server/redis

redis]# cat dev.sh
#!/bin/bash
#

d_data_root='/data/server/redis'
f_prefix='redis'
f_ns='dev'
f_port='6379'

cd ${d_data_root}
mkdir -pv ${f_ns}
docker run -d --restart=always \
  --name "${f_prefix}-${f_ns}" \
  -p ${f_port}:6379 \
  -v /etc/localtime:/etc/localtime \
  -v "${d_data_root}/${f_ns}":/data \
  redis

docker ps -f name="${f_prefix}-${f_ns}"

# test
docker run -it --link "${f_prefix}-${f_ns}":redis --rm redis redis-cli -h redis -p 6379

```
