# mongodb-在docker中运行
2018/11/19



### 部署
```bash
~]# mkdir -p /data/server/mongodb
~]# cd /data/server/mongodb

mongodb]# cat dev.sh
#!/bin/bash
#

d_data_root='/data/server/mongodb'
f_prefix='mongodb'
f_ns='dev'
f_port='27017'

cd ${d_data_root}
mkdir -pv ${f_ns}
docker run -d --restart=always --name "${f_prefix}-${f_ns}" -v "${d_data_root}/${f_ns}":/data/db -p ${f_port}:27017 mongo
docker ps -f name="${f_prefix}-${f_ns}"

# test
docker run -it --link "${f_prefix}-${f_ns}":mongo --rm mongo sh -c 'exec mongo "$MONGO_PORT_27017_TCP_ADDR:$MONGO_PORT_27017_TCP_PORT/test"'

```
