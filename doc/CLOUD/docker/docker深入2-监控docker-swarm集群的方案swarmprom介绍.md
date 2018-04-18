# docker深入2-监控docker-swarm集群的方案swarmprom介绍
2018/4/18


### 本文目的
* 引导
* 本地化

### 简介
> 相信您也对如何监控容器化的业务感到烦恼，在此先强烈推荐您体验一下 `swarmprom` 这个演示方案，期待能帮助您打造出适合自身场景的监控方案
> Swarmprom is a starter kit for Docker Swarm monitoring with Prometheus, Grafana, cAdvisor, Node Exporter, Alert Manager and Unsee.

简而言之，该方案是以下工具的组合：

> `caddy`

网关，提供了基础的认证功能

> grafana

数据展示
`http://<swarm-ip>:3000`

> prometheus

数据源
`http://<swarm-ip>:9090`

> alertmanager

告警
`http://<swarm-ip>:9093`

> unsee

告警面板
`http://<swarm-ip>:9094`

> cAdvisor

容器 metrics 收集

> nodeExporter

主机 metrics 收集



### 本地化 - alertmanager
`alertmanager` 的告警 `receiver` 默认设置的是 `slack` （这工具好用，只是你懂的，在国内网络用起来不方便）

切换成 `wechat` 来接收告警，更符合国人的习惯


##### alertmanager - wechat

* `wechat` 相关的 PR
  - prometheus/alertmanager
    - [#1059](https://github.com/prometheus/alertmanager/pull/1059)
  - prometheus/docs
    - [#977](https://github.com/prometheus/docs/pull/977)


* 在这个 branch 中，更新的配置文件包含:
  - `alertmanager/conf/alertmanager.yml`
    - 使用 wechat 作为 receiver 的配置模版
  - `alertmanager/conf/docker-entrypoint.sh`
    - 使用 wechat 作为 receiver 的启动脚本
  - `docker-compose.yml`
    - 更换 `alertmanager` 的镜像为使用了 `wechat` 的版本
    - 传递 `wechat` 相关的环境变量

> `docker-compose.yml` 变更的内容为
```yaml
alertmanager:
  image: opera443399/swarmprom-alertmanager:v0.14.0
  networks:
    - net
  environment:
    - API_SECRET=${API_SECRET}
    - CORP_ID=${CORP_ID}
    - AGENT_ID=${AGENT_ID}
    - TO_PARTY=${TO_PARTY}

```

> 请通过 `环境变量` 来提供 `wechat` 对应的 `API_SECRET`, `CORP_ID`, `AGENT_ID` 和 `TO_PARTY`

*示例中使用了一个脚本 `start.sh` 来简化操作*

```bash
$ git clone https://github.com/opera443399/swarmprom.git
$ cd swarmprom
$ git checkout -b feat-alertmanager-receiver-wechat remotes/origin/feat-alertmanager-receiver-wechat
$ cat start.sh
#!/bin/bash
#

ADMIN_USER='admin' \
ADMIN_PASSWORD='admin' \
API_SECRET='xxx' \
CORP_ID='xxx' \
AGENT_ID='111' \
TO_PARTY='111' \
docker stack deploy -c docker-compose.yml mon

```

##### 准备工作
* 请先确认 `docker-compose.yml` 中定义的 `DOCKER_GWBRIDGE_IP` 和 `/var/lib/docker` 是正确的值
```bash
##### 配置中默认的 `IP` 是 `172.18.0.1` 如果不一致请替换
# ip -o addr show docker_gwbridge
3: docker_gwbridge    inet 172.18.0.1/16 scope global docker_gwbridge\       valid_lft forever preferred_lft forever

##### 查看 docker 的根目录
# docker info |grep 'Docker Root Dir'
Docker Root Dir: /var/lib/docker

```

* 配置收集 `docker metrics`
```bash
##### 在 docker 的配置 `daemon.json` 中增加 `metrics-addr` 相关指令
##### 请注意，为了在容器内通过 `DOCKER_GWBRIDGE_IP` 来收集数据，使用的 ip 不是 `127.0.0.1:9323` 而是 `0.0.0.0:9323`
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}

```


##### 启动监控 `swarmprom`
```bash
$ sh start.sh

```



### ZYXW、参考
1. [Docker Swarm instrumentation with Prometheus](https://stefanprodan.com/2017/docker-swarm-instrumentation-with-prometheus/)
2. [To configure the Docker daemon as a Prometheus target, you need to specify the metrics-address](https://docs.docker.com/config/thirdparty/prometheus/#configure-docker)
