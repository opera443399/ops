# 使用kubeadm部署k8s集群02-配置etcd高可用
2018/1/4



### 配置 etcd 高可用
  - 新建一个 2 节点的 etcd cluster
  - 查看 etcd 的状态
  - 迁移原来 master 节点上的 etcd 数据到上面新建的 etcd cluster 中
  - 切换 kube-apiserver 使用新的 etcd endpoint 地址
  - 清理掉原来的单节点 etcd 服务
  - 重建一个 etcd 服务，加入新集群
  - 部署新的 etcd 节点
  - 更新另外2个节点的 etcd.yaml 配置

##### 新建一个 2 节点的 etcd cluster
```bash
### 基于当前 master 节点 tvm-00 的 etcd 配置来修改：
[root@tvm-00 ~]# scp /etc/kubernetes/manifests/etcd.yaml 10.10.9.68:/tmp/
[root@tvm-00 ~]# scp /etc/kubernetes/manifests/etcd.yaml 10.10.9.69:/tmp/

### 修改 etcd 配置，设置成一个全新的 cluster
[root@tvm-01 ~]# cat /tmp/etcd.yaml
### (略过部分没有改动的输出内容)
spec:
  containers:
  - command:
    - etcd
    - --name=etcd-01
    - --initial-advertise-peer-urls=http://10.10.9.68:2380
    - --listen-peer-urls=http://10.10.9.68:2380
    - --listen-client-urls=http://127.0.0.1:2379,http://10.10.9.68:2379
    - --advertise-client-urls=http://10.10.9.68:2379
    - --initial-cluster-token=etcd-cluster
    - --initial-cluster=etcd-01=http://10.10.9.68:2380,etcd-02=http://10.10.9.69:2380
    - --initial-cluster-state=new
    - --data-dir=/var/lib/etcd
    image: gcr.io/google_containers/etcd-amd64:3.1.10
### (略过部分没有改动的输出内容)

[root@tvm-02 ~]# cat /tmp/etcd.yaml
### (略过部分没有改动的输出内容)
spec:
  containers:
  - command:
    - etcd
    - --name=etcd-02
    - --initial-advertise-peer-urls=http://10.10.9.69:2380
    - --listen-peer-urls=http://10.10.9.69:2380
    - --listen-client-urls=http://127.0.0.1:2379,http://10.10.9.69:2379
    - --advertise-client-urls=http://10.10.9.69:2379
    - --initial-cluster-token=etcd-cluster
    - --initial-cluster=etcd-01=http://10.10.9.68:2380,etcd-02=http://10.10.9.69:2380
    - --initial-cluster-state=new
    - --data-dir=/var/lib/etcd
    image: gcr.io/google_containers/etcd-amd64:3.1.10
### (略过部分没有改动的输出内容)

### 启动 etcd cluster
### 配置文件同步到 manifests 后将会被 kubelet 检测到然后自动将 pod 启动
[root@tvm-01 ~]# rm /var/lib/etcd -fr
[root@tvm-01 ~]# cp -a /tmp/etcd.yaml /etc/kubernetes/manifests/

[root@tvm-02 ~]# rm /var/lib/etcd -fr
[root@tvm-02 ~]# cp -a /tmp/etcd.yaml /etc/kubernetes/manifests/
```

##### 查看 etcd 的状态
```bash
### 下载一个 etcdctl 工具来管理集群：
[root@tvm-00 ~]# cd /usr/local/bin/
[root@tvm-00 ~]# wget https://github.com/coreos/etcd/releases/download/v3.1.10/etcd-v3.1.10-linux-amd64.tar.gz
[root@tvm-00 ~]# tar zxf etcd-v3.1.10-linux-amd64.tar.gz
[root@tvm-00 ~]# mv etcd-v3.1.10-linux-amd64/etcd* .
[root@tvm-00 ~]# ETCDCTL_API=3 etcdctl --endpoints "http://10.10.9.68:2379,http://10.10.9.69:2379" endpoint status
http://10.10.9.68:2379, 21b9c7066a7e525, 3.1.10, 25 kB, true, 7, 194
http://10.10.9.69:2379, 516e519b2158e83a, 3.1.10, 25 kB, false, 7, 194

### 注意：输出的列从左到右分别表示：endpoint URL, ID, version, database size, leadership status, raft term, and raft status.
### 符合预期。
```

##### 迁移原来 master 节点上的 etcd 数据到上面新建的 etcd cluster 中
```bash
### 注意：etcdctl 3.x 版本提供了一个 make-mirror 功能来同步数据
### 在当前 master 节点 tvm-00 上执行：
[root@tvm-00 ~]# ETCDCTL_API=3 etcdctl make-mirror --no-dest-prefix=true --endpoints=127.0.0.1:2379 --insecure-skip-tls-verify=true 10.10.9.68:2379

### 将数据同步到远端刚才新建的 etcd 集群中
### 注意1：数据是从 127.0.0.1:2379 写入到 10.10.9.68:2379
### 注意2：这个同步只能是手动中止，间隔 30s 打印一次输出

### 通过对比集群到状态来判断是否同步完成：
###（新开一个窗口）
[root@tvm-00 ~]# ETCDCTL_API=3 etcdctl endpoint status
127.0.0.1:2379, 8e9e05c52164694d, 3.1.10, 1.9 MB, true, 2, 342021

[root@tvm-00 ~]# ETCDCTL_API=3 etcdctl --endpoints "http://10.10.9.68:2379,http://10.10.9.69:2379" endpoint status
http://10.10.9.68:2379, 21b9c7066a7e525, 3.1.10, 1.9 MB, true, 7, 1794
http://10.10.9.69:2379, 516e519b2158e83a, 3.1.10, 1.9 MB, false, 7, 1794
```

##### 切换 kube-apiserver 使用新的 etcd endpoint 地址
```bash

### 停止 kubelet 服务：
[root@tvm-00 ~]# systemctl stop kubelet

### 更新 kube-apiserver.yaml 中 etcd 服务到地址，切到我们到新集群中：
[root@tvm-00 ~]# sed -i 's#127.0.0.1:2379#10.10.9.68:2379#' /etc/kubernetes/manifests/kube-apiserver.yaml

### 启动 kubelet 服务：
[root@tvm-00 ~]# systemctl start kubelet
[root@tvm-00 ~]# kubectl get pods --all-namespaces |grep 'etcd-tvm'
kube-system   etcd-tvm-00                      1/1       Running   1          4h
kube-system   etcd-tvm-01                      1/1       Running   0          1h
kube-system   etcd-tvm-02                      1/1       Running   0          1h
```

##### 清理掉原来的单节点 etcd 服务
```bash
[root@tvm-00 ~]# mv /etc/kubernetes/manifests/etcd.yaml /tmp/orig.master.etcd.yaml
[root@tvm-00 ~]# mv /var/lib/etcd /tmp/orig.master.etcd
### 观察 pods 的变化：
[root@tvm-00 ~]# kubectl get pods --all-namespaces |grep 'etcd-tvm'
kube-system   etcd-tvm-01                      1/1       Running   0          1h
kube-system   etcd-tvm-02                      1/1       Running   0          1h

### 符合预期 etcd-tvm-00 停止服务
```

##### 重建一个 etcd 服务，加入新集群
```bash
[root@tvm-00 ~]# cat /tmp/etcd.yaml
### (略过部分没有改动的输出内容)
spec:
  containers:
  - command:
    - etcd
    - --name=etcd-00
    - --initial-advertise-peer-urls=http://10.10.9.67:2380
    - --listen-peer-urls=http://10.10.9.67:2380
    - --listen-client-urls=http://127.0.0.1:2379,http://10.10.9.67:2379
    - --advertise-client-urls=http://10.10.9.67:2379
    - --initial-cluster-token=etcd-cluster
    - --initial-cluster=etcd-00=http://10.10.9.67:2380,etcd-01=http://10.10.9.68:2380,etcd-02=http://10.10.9.69:2380
    - --initial-cluster-state=existing
    - --data-dir=/var/lib/etcd
    image: gcr.io/google_containers/etcd-amd64:3.1.10
### (略过部分没有改动的输出内容)


### 注意：上述新节点的配置有一个地方不一样：
--initial-cluster-state=existing
```

- 先配置 etcd cluster 增加一个 member 用于后续操作
```bash
[root@tvm-00 ~]# ETCDCTL_API=3 etcdctl --endpoints="http://10.10.9.68:2379" member list
21b9c7066a7e525, started, etcd-01, http://10.10.9.68:2380, http://10.10.9.68:2379
516e519b2158e83a, started, etcd-02, http://10.10.9.69:2380, http://10.10.9.69:2379

[root@tvm-00 ~]# ETCDCTL_API=3 etcdctl --endpoints="http://10.10.9.68:2379" member add etcd-00 --peer-urls=http://10.10.9.67:2380
Member 6cc2e7728adb6b28 added to cluster 3742ed98339167da

ETCD_NAME="etcd-00"
ETCD_INITIAL_CLUSTER="etcd-01=http://10.10.9.68:2380,etcd-02=http://10.10.9.69:2380,etcd-00=http://10.10.9.67:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"

[root@tvm-00 ~]# ETCDCTL_API=3 etcdctl --endpoints="http://10.10.9.68:2379" member list
21b9c7066a7e525, started, etcd-01, http://10.10.9.68:2380, http://10.10.9.68:2379
516e519b2158e83a, started, etcd-02, http://10.10.9.69:2380, http://10.10.9.69:2379
6cc2e7728adb6b28, unstarted, , http://10.10.9.67:2380,
```

##### 部署新的 etcd 节点
```bash
[root@tvm-00 ~]# rm /var/lib/etcd -fr
[root@tvm-00 ~]# cp -a /tmp/etcd.yaml /etc/kubernetes/manifests/

### 再次查看 k8s cluster 信息

[root@tvm-00 ~]# kubectl get pods --all-namespaces |grep 'etcd-tvm'
kube-system   etcd-tvm-00                      1/1       Running   1          4h
kube-system   etcd-tvm-01                      1/1       Running   0          1h
kube-system   etcd-tvm-02                      1/1       Running   0          1h

### etcd 的日志：
[root@tvm-00 ~]# kubectl logs -n kube-system --tail=20 etcd-tvm-00

### etcd clister 状态：
[root@tvm-00 ~]# ETCDCTL_API=3 etcdctl --endpoints="http://10.10.9.67:2379,http://10.10.9.68:2379,http://10.10.9.69:2379" member list
21b9c7066a7e525, started, etcd-01, http://10.10.9.68:2380, http://10.10.9.68:2379
516e519b2158e83a, started, etcd-02, http://10.10.9.69:2380, http://10.10.9.69:2379
6cc2e7728adb6b28, started, etcd-00, http://10.10.9.67:2380, http://10.10.9.67:2379

[root@tvm-00 ~]# ETCDCTL_API=3 etcdctl --endpoints "http://10.10.9.67:2379,http://10.10.9.68:2379,http://10.10.9.69:2379" endpoint status
http://10.10.9.67:2379, 6cc2e7728adb6b28, 3.1.10, 3.8 MB, false, 7, 5236
http://10.10.9.68:2379, 21b9c7066a7e525, 3.1.10, 3.3 MB, true, 7, 5236
http://10.10.9.69:2379, 516e519b2158e83a, 3.1.10, 3.3 MB, false, 7, 5236
```

##### 更新另外2个节点的 etcd.yaml 配置
```bash
### 区别之处：

- --initial-cluster=etcd-00=http://10.10.9.67:2380,etcd-01=http://10.10.9.68:2380,etcd-02=http://10.10.9.69:2380
- --initial-cluster-state=existing

### 将节点 tvm-00 上 kube-apiserver 使用的 etcd endpoint 切换回来
[root@tvm-00 ~]# sed -i 's#10.10.9.68:2379#127.0.0.1:2379#' /etc/kubernetes/manifests/kube-apiserver.yaml
[root@tvm-00 ~]# kubectl get pods --all-namespaces |grep api
kube-system   kube-apiserver-tvm-00            1/1       Running   0          1m

```
