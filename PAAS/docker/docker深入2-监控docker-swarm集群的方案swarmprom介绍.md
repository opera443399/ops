# docker深入2-监控docker-swarm集群的方案swarmprom介绍
2018/4/28


### 本文目的
* 引导
* 本地化

### 简介
---
相信您也对如何监控容器化的业务感到烦恼，在此先强烈推荐您体验一下 `swarmprom` 这个演示方案，期待能帮助您打造出适合自身场景的监控方案

> Swarmprom is a starter kit for Docker Swarm monitoring with Prometheus, Grafana, cAdvisor, Node Exporter, Alert Manager and Unsee.

简而言之，该方案是以下工具的组合：

* `caddy` 网关，提供了基础的认证功能
* `grafana` 数据展示 `http://<swarm-ip>:3000`
* `prometheus` 数据源 `http://<swarm-ip>:9090`
* `alertmanager` 告警 `http://<swarm-ip>:9093`
* `unsee` 告警看板 `http://<swarm-ip>:9094`
* `cAdvisor` 容器 metrics 收集
* `nodeExporter` 主机 metrics 收集



### 本地化 - alertmanager 的告警方式切换成 `wechat`
---
`alertmanager` 的告警 `receiver` 默认设置的是 `slack` （这工具好用，只是你懂的，在国内网络用起来不方便）

切换成 `wechat` 来接收告警，更符合国人的习惯


- `wechat` 相关的 PR
  - prometheus/alertmanager
    - [#1059](https://github.com/prometheus/alertmanager/pull/1059)
  - prometheus/docs
    - [#977](https://github.com/prometheus/docs/pull/977)

> 通过上述 2 个 PR 可以发现 wechat 相关的配置指南(文末简介)


- 在这个 branch 中，更新的配置文件包含:
  - `alertmanager/conf/alertmanager.yml`
    - 使用 wechat 作为 receiver 的配置模版
  - `alertmanager/templates/wechat.tmpl`
    - 自定义告警内容的模版
  - `docker-compose.yml`
    - 更换 `alertmanager` 的镜像为 `prom` 官方默认的的版本
    - 通过 volume 映射来传递 `wechat` 相关的配置

其中，`docker-compose.yml` 变更的内容为：
```yaml
alertmanager:
  image: prom/alertmanager:v0.14.0
  networks:
    - net
  volumes:
    - alertmanager:/alertmanager
    - ./alertmanager/conf/alertmanager.yml:/etc/alertmanager/config.yml
    - ./alertmanager/templates:/etc/alertmanager/templates

```


示例中使用了一个脚本 `start.sh` 来简化操作

```bash
$ git clone https://github.com/opera443399/swarmprom.git
$ cd swarmprom
$ git checkout -b feat-alertmanager-receiver-wechat remotes/origin/feat-alertmanager-receiver-wechat
### 设置 wechat
$ vim alertmanager/conf/alertmanager.yml
### 设置访问账号
$ vim start.sh
#!/bin/bash
#

ADMIN_USER='admin' \
ADMIN_PASSWORD='admin' \
docker stack deploy -c docker-compose.yml mon

```


请先确认 `docker-compose.yml` 中定义的 `DOCKER_GWBRIDGE_IP` 和 `/var/lib/docker` 是正确的值
```bash
##### 配置中默认的 `IP` 是 `172.18.0.1` 如果不一致请替换
# ip -o addr show docker_gwbridge
3: docker_gwbridge    inet 172.18.0.1/16 scope global docker_gwbridge\       valid_lft forever preferred_lft forever

##### 查看 docker 的根目录
# docker info |grep 'Docker Root Dir'
Docker Root Dir: /var/lib/docker

```

配置 docker 节点
```bash
##### 在 docker 的配置 `daemon.json` 中增加 `metrics-addr` 相关指令
##### 请注意，为了在容器内通过 `DOCKER_GWBRIDGE_IP` 来收集数据，使用的 ip 不是 `127.0.0.1:9323` 而是 `0.0.0.0:9323`
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}

```


启动监控 `swarmprom`
```bash
$ sh start.sh

```


### wechat 相关的文档介绍
文档来源：
https://github.com/simonpasquier/docs/blob/700fac224efc28d5ab9905e971e452e52e8e77a7/content/docs/alerting/configuration.md


`<wechat_config>`

```yaml
# Whether or not to notify about resolved alerts.
[ send_resolved: <boolean> | default = false ]

# The API key to use when talking to the Wechat API.
[ api_secret: <secret> | default = global.wechat_secret_url ]

# The Wechat API URL.
[ api_url: <string> | default = global.wechat_api_url ]

# The corp id for authentication
[ corp_id: <string> | default = global.wechat_api_corp_id ]

# API request data as defined by the Wechat API.
[ message: <tmpl_string> | default = '{{ template "wechat.default.message" . }}' ]
[ agent_id: <string> | default = '{{ template "wechat.default.agent_id" . }}' ]
[ to_user: <string> | default = '{{ template "wechat.default.to_user" . }}' ]
[ to_party: <string> | default = '{{ template "wechat.default.to_party" . }}' ]
[ to_tag: <string> | default = '{{ template "wechat.default.to_tag" . }}' ]
```


重点请关注这一行：
```yaml
[ message: <tmpl_string> | default = '{{ template "wechat.default.message" . }}' ]
```

这个默认的 message 的模版来源：
https://github.com/prometheus/alertmanager/blob/master/template/default.tmpl

是的，已经被合并到 master 上啦。

其中，定义的默认 `message` 格式为：
```yaml
{{ define "__subject" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .GroupLabels.SortedPairs.Values | join " " }} {{ if gt (len .CommonLabels) (len .GroupLabels) }}({{ with .CommonLabels.Remove .GroupLabels.Names }}{{ .Values | join " " }}{{ end }}){{ end }}{{ end }}

{{ define "__text_alert_list" }}{{ range . }}Labels:
{{ range .Labels.SortedPairs }} - {{ .Name }} = {{ .Value }}
{{ end }}Annotations:
{{ range .Annotations.SortedPairs }} - {{ .Name }} = {{ .Value }}
{{ end }}Source: {{ .GeneratorURL }}
{{ end }}{{ end }}


{{ define "wechat.default.message" }}{{ template "__subject" . }}
{{ .CommonAnnotations.SortedPairs.Values | join " " }}
{{ if gt (len .Alerts.Firing) 0 -}}
Alerts Firing:
{{ template "__text_alert_list" .Alerts.Firing }}
{{- end }}
{{ if gt (len .Alerts.Resolved) 0 -}}
Alerts Resolved:
{{ template "__text_alert_list" .Alerts.Resolved }}
{{- end }}
AlertmanagerUrl:
{{ template "__alertmanagerURL" . }}
{{- end }}
```

您也可以自定义 `message` 来格式化数据实例，请参考示例：
```
$ vim alertmanager/templates/wechat.tmpl
```


### ZYXW、参考
1. [Docker Swarm instrumentation with Prometheus](https://stefanprodan.com/2017/docker-swarm-instrumentation-with-prometheus/)
2. [To configure the Docker daemon as a Prometheus target, you need to specify the metrics-address](https://docs.docker.com/config/thirdparty/prometheus/#configure-docker)
