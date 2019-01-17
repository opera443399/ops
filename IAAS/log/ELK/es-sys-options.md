# es sys options

2019/1/17

## ulimit

通常系统运维已经在标准化时，提高了 `nofile,nproc` 等参数，否则需要配置

```bash
ulimit -n 65535
ulimit -u 4096

```

## sysctl

Elasticsearch uses a mmapfs directory by default to store its indices. The default operating system limits on mmap counts is likely to be too low, which may result in out of memory exceptions.

```bash
sysctl -w vm.max_map_count=262144
echo 'sysctl -w vm.max_map_count=262144' >>/etc/sysctl.conf

```

## 禁止 swap

swap严重影响性能稳定，宁愿让 OS kill 掉

```bash
swapoff -a
```


## 关于 bootstrap.memory_lock: true 的使用注意

`mlockall might cause the JVM or shell session to exit if it tries to allocate more memory than is available!`


## 关于节点角色

小集群采用默认，大集群则独立 master node

```
To create a dedicated master-eligible node, set:

node.master: true
node.data: false
node.ingest: false
cluster.remote.connect: false


The node.master role is enabled by default.
Disable the node.data role (enabled by default).
Disable the node.ingest role (enabled by default).
Disable cross-cluster search (enabled by default).

note:
These settings apply only when X-Pack is not installed

```


## 参考
1. [disable swap](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html)
2. [master node](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#master-node)
