# 使用kubeadm部署k8s集群05-配置kubectl访问kube-apiserver
2018/1/4


### 配置 kubectl 访问 kube-apiserver
  - 切换 master 节点连接到本节点的 apiserver
  - 确认集群信息

##### 切换 master 节点连接到本节点的 apiserver
```bash
### 为了在这 2 个新的节点执行 kubectl 需要配置 admin.yaml
[root@tvm-00 ~]# mkdir -p ~/k8s_install/master/admin
[root@tvm-00 ~]# cd !$

[root@tvm-00 admin]# cp -a /etc/kubernetes/admin.conf tvm-01.admin.conf
[root@tvm-00 admin]# sed -i 's#10.10.9.67:6443#10.10.9.68:6443#' tvm-01.admin.conf
[root@tvm-00 admin]# scp tvm-01.admin.conf 10.10.9.68:/etc/kubernetes/admin.conf

[root@tvm-01 ~]# mkdir -p $HOME/.kube
[root@tvm-01 ~]# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

### 同样的操作，在另一个节点上执行：
[root@tvm-00 admin]# cp -a /etc/kubernetes/admin.conf tvm-02.admin.conf
[root@tvm-00 admin]# sed -i 's#10.10.9.67:6443#10.10.9.69:6443#' tvm-02.admin.conf
[root@tvm-00 admin]# scp tvm-02.admin.conf 10.10.9.69:/etc/kubernetes/admin.conf

[root@tvm-01 ~]# mkdir -p $HOME/.kube
[root@tvm-01 ~]# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```

##### 确认集群信息
```bash
[root@tvm-01 ~]# kubectl cluster-info
Kubernetes master is running at https://10.10.9.68:6443
KubeDNS is running at https://10.10.9.68:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

[root@tvm-02 ~]# kubectl cluster-info
Kubernetes master is running at https://10.10.9.69:6443
KubeDNS is running at https://10.10.9.69:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

### 上述信息显示，每个节点已经连接到本机的 apiserver 上
```
