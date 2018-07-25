# 容器日志收集方案探索之log-pilot
2018/7/25

> log-pilot: 阿里云开源的日志采集器

具有如下特性：

* 一个单独的 log 进程收集机器上所有容器的日志。不需要为每个容器启动一个 log 进程。
* 支持文件日志和 stdout。docker log dirver 亦或 logspout 只能处理 stdout，log-pilot 不仅支持收集 stdout 日志，还可以收集文件日志。
* 声明式配置。当您的容器有日志要收集，只要通过 label 声明要收集的日志文件的路径，无需改动其他任何配置，log-pilot 就会自动收集新容器的日志。
* 支持多种日志存储方式。无论是强大的阿里云日志服务，还是比较流行的 elasticsearch 组合，甚至是 graylog，log-pilot 都能把日志投递到正确的地点。
* 开源。log-pilot 完全开源，您可以从 这里 下载代码。如果现有的功能不能满足您的需要，欢迎提 issue。


下面以 graylog 为例，描述部署一个简易的日志服务的基本步骤。

##### elasticsearch+graylog
先给 docker node 打一个标签来调度该服务的部署：
```bash
docker node update --label-add 'deploy.env=swarmlog' 10.50.200.101
```

初始化：
```bash
$ cat graylog.sh
#!/bin/bash
#
# 2018/7/25

GRAYLOG_PASSWORD_SECRET='graylog-password-secret' \
GRAYLOG_ROOT_PASSWORD_SHA2='8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918' \
GRAYLOG_WEB_ENDPOINT_URI='http://10.50.200.101:9000/api' \
docker stack deploy -c docker-compose.yml logs

```

##### 日志 agent 在每个 docker node 上运行
```bash
$ cat log-pilot.sh
#!/bin/bash
#
# 2018/7/25

docker rm -f log-pilot
docker run -d --rm -it \
    --name log-pilot \
    -v /etc/localtime:/etc/localtime \
    -v /etc/timezone:/etc/timezone \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /:/host \
    --privileged \
    -e PILOT_TYPE="fluentd" \
    -e FLUENTD_OUTPUT="graylog" \
    -e GRAYLOG_HOST="10.50.200.101" \
    -e GRAYLOG_PORT="12201" \
    registry.cn-hangzhou.aliyuncs.com/acs-sample/log-pilot:latest

```


##### 收集容器日志的方式1：指定 `--log-driver`
```bash
docker run -d --rm -it \
    --name t001 \
    -p 10001:80 \
    --log-driver=gelf \
    --log-opt gelf-address=udp://10.50.200.101:12201 \
    --log-opt tag="log-t001" \
    opera443399/whoami:0.9

```

##### 收集容器日志的方式2：指定 `--label`
```bash
docker run -d --rm -it \
    --name t002 \
    -p 10002:80 \
    --label aliyun.logs.t002=stdout \
    opera443399/whoami:0.9

```


##### 收集容器日志的方式3：在 docker swarm service 模式下指定 `--container-label-add`
```bash
docker service update --with-registry-auth --container-label-add "aliyun.logs.t003=stdout" t003

```



##### ZYXW、参考
1. [Docker 日志收集新方案：log-pilot](https://help.aliyun.com/document_detail/50441.html)
2. [log-pilot](https://github.com/AliyunContainerService/log-pilot)
