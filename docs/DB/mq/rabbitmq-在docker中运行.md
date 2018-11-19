# rabbitmq-在docker中运行
2018/11/19


### rabbitmq management 配置示例
```bash
~]# cat devv/etc/enabled_plugins
[rabbitmq_management,rabbitmq_tracing].

~]# cat dev/etc/rabbitmq.conf
loopback_users.guest = false
listeners.tcp.default = 5672
hipe_compile = false
management.listener.port = 15672
management.listener.ssl = false

```


### 部署
```bash
~]# mkdir -p /data/server/rabbitmq
~]# cd /data/server/rabbitmq

rabbitmq]# cat dev.sh
#!/bin/bash
#

d_data_root='/data/server/rabbitmq'
f_prefix='rabbitmq'
f_ns='dev'
f_port='5672'
f_port_m='15672'

cd ${d_data_root}
mkdir -pv ${f_ns}
docker run -d --restart=always --name "${f_prefix}-${f_ns}" \
--hostname "${f_prefix}-${f_ns}" \
-v "${d_data_root}/${f_ns}/data":/var/lib/rabbitmq \
-v "${d_data_root}/${f_ns}/etc":/etc/rabbitmq \
-p ${f_port}:5672 \
-p ${f_port_m}:15672 \
registry.cn-hangzhou.aliyuncs.com/ns-ofo/image-base-rabbitmq:v0.1

docker ps -f name="${f_prefix}-${f_ns}"


# test
echo "visit http://$(ip a |grep global |grep eth0 |awk '{print $2}' |cut -d'/' -f1):12311"

```
