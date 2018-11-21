# redis-cluster-在docker中运行
2018/11/19



### 部署
```bash
~]# mkdir -p /data/server/redis-cluster
~]# cd /data/server/redis-cluster

redis]# cat dev.sh
#!/bin/bash
#

d_data_root='/data/server/redis-cluster'
f_prefix='redis-cluster'
f_ns='dev'

cd ${d_data_root}
mkdir -pv ${f_ns}
docker run -d --restart=always --name "${f_prefix}-${f_ns}" -v "${d_data_root}/${f_ns}":/redis-data -p "7000-7005:7000-7005" grokzen/redis-cluster:4.0.11
docker ps -f name="${f_prefix}-${f_ns}"

# test
sleep 2s
docker run -it --link "${f_prefix}-${f_ns}":redis --rm redis redis-cli -h redis -p 7000

```
