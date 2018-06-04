# docker深入2-UI之 portainer 的使用简介
2017/6/4

### 前言
预计该 UI 仅满足部分需求，还有坑要填，部分需求得自己去实现。

### 配置实例
##### 配置防火墙
示例：
```bash
iptables -A INPUT -s 192.168.200.0/24 -p tcp -m tcp --dport 2375 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 2375 -j DROP
```

最好是通过安全组之类的来限制，不要暴露到外网，以免未授权访问。

##### 调整docker访问，允许内网访问 API 接口
```bash
sed -i "/^ExecStart/c ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://$(ip a |grep global |grep eth0 |awk '{print $2}' |cut -d'/' -f1):2375" /usr/lib/systemd/system/docker.service
systemctl daemon-reload; systemctl restart docker
```

##### 启动 portainer
- **关于存储**
首先，引用以下一段话，来表达数据持久化时要考虑的细节：
https://docs.docker.com/engine/admin/volumes/bind-mounts/#choosing-the--v-or-mount-flag
```
Differences between -v and --mount behavior
Because the -v and --volume flags have been a part of Docker for a long time, their behavior cannot be changed. This means that there is one behavior that is different between -v and --mount.

If you use -v or --volume to bind-mount a file or directory that does not yet exist on the Docker host, -v will create the endpoint for you. It is always created as a directory.

If you use --mount to bind-mount a file or directory that does not yet exist on the Docker host, Docker does not automatically create it for you, but generates an error.
```

（本次示例仅在swarm集群的其中一个节点创建该目录即可，这样一来，没有该目录的节点，启动服务时将报错，后续可考虑使用 NFS 之类的共享存储来存放数据。）


- **关于agent**
使用 swarm 集群的方式运行，且使用了一个 portainer 团队决定闭源的 agent 来达到管理整个集群的目的，详情请参考：
https://portainer.readthedocs.io/en/latest/agent.html#agent
```
Release 1.17.0
1.17.0
This version introduce support for connecting Portainer to a Portainer agent. It gives the ability to inspect and manage any resource inside a Swarm cluster within a single Portainer endpoint, solving #461

Agent
Add agent support: #461, #1828
```

- **部署**
```bash
mkdir /data/server/portainer -p
docker network create --driver overlay net-portainer

docker service create \
    --name portainer-agent \
    --detach=true \
    --network net-portainer \
    -e AGENT_CLUSTER_ADDR=tasks.portainer-agent \
    --mode global \
    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    portainer/agent

docker service create \
    --name portainer \
    --detach=true \
    --network net-portainer \
    --publish 9000:9000 \
    --replicas=1 \
    --constraint 'node.role == manager' \
    --mount type=bind,src=/data/server/portainer,dst=/data \
    portainer/portainer -H "tcp://tasks.portainer-agent:9001" --tlsskipverify
```

- **访问UI界面**
http://node_ip:9000
设置管理员密码。



### FAQ
##### 在 UI 中 `service restart policy` 默认值为 `none` 的疑惑。
UI创建的 `service` 在页面显示策略的值为 `none` 但实际测试发现：

默认策略是：`any`
```bash
~]# docker service inspect --format '{{ .Spec.TaskTemplate.RestartPolicy.Condition }}' t001
any
```

且测试集群一个 node 下线后，指定的 service 的副本是否会自动漂移到其他 node 时发现：
命令行得到的的结果，符合预期；
UI 得到的结果，不符合预期；（任务还在已经下线的 node 中显示为 running 状态）

结论： UI 的显示错误。



### ZYXW、参考
1. [portainer doc](https://portainer.readthedocs.io/en/latest/deployment.html)
2. [github](https://github.com/portainer/portainer/releases)
3. [#461](https://github.com/portainer/portainer/issues/461)
4. [#1828](https://github.com/portainer/portainer/pull/1828)
