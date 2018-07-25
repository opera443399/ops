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
注意 graylog 在容器中运行时，可以注入环境变量，变量名称的小技巧是：
参考 `graylog配置文件` 中定义的变量，变成大写字符，加上前缀： `GRAYLOG_`

初始化：
```bash
# sh es.sh
# sh mongodb.sh
# sh graylog.sh

```

##### 日志 agent 在每个 docker node 上运行
```bash
$ sh log-pilot.sh

```


##### 收集容器日志的方式1：指定 `--log-driver`
```bash
docker run -d --rm -it \
    --name t001 \
    -p 10001:80 \
    --log-driver=gelf \
    --log-opt gelf-address=udp://10.6.27.68:12201 \
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
3. [graylog-image](https://hub.docker.com/r/graylog/graylog/)
3. [graylog配置文件](https://github.com/Graylog2/graylog-docker/blob/2.4/config/graylog.conf)
