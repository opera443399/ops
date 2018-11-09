# redis-在docker中运行
2018/11/9



### 部署
```bash
~]# mkdir -p /data/server/redis
~]# cd /data/server/redis

redis]# cat dev.sh
#!/bin/bash
#
# 2018/11/9

d_data_root='/data/server/redis'
f_prefix='redis'
f_ns='dev'
f_port='6379'

cd ${d_data_root}
mkdir -pv ${f_ns}
docker run -d --restart=always --name "${f_prefix}-${f_ns}" -v "${d_data_root}/${f_ns}":/data -p ${f_port}:6379 redis
docker ps -f name="${f_prefix}-${f_ns}"

# test
docker run -it --link "${f_prefix}-${f_ns}":redis --rm redis redis-cli -h redis -p 6379

```
