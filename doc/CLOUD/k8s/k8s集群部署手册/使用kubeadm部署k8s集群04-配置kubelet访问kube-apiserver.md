# 使用kubeadm部署k8s集群04-配置kubelet访问kube-apiserver
2018/1/4


### 配置 kubelet 访问 kube-apiserver
  - 切换 master 节点连接到本节点的 apiserver
  - 切换 worker 节点连接到 apiserver 的 LB 入口(在对应的文档中记录)
    - 前提：这个 LB 已经部署完成

##### 切换 master 节点连接到本节点的 apiserver
```bash
[root@tvm-01 ~]# sed -i 's#https://10.10.9.67:6443#https://10.10.9.68:6443#' /etc/kubernetes/kubelet.conf
[root@tvm-01 ~]# systemctl restart kubelet

[root@tvm-02 ~]# sed -i 's#https://10.10.9.67:6443#https://10.10.9.69:6443#' /etc/kubernetes/kubelet.conf
[root@tvm-02 ~]# systemctl restart kubelet

### 观察日志，暂未发现异常
### 观察 tcp 链接
[root@tvm-00 ~]# ss -antp4 |grep 10.10.9.67:6443
ESTAB      0      0      10.10.9.67:27162              10.10.9.67:6443                users:(("kubelet",pid=21837,fd=27))
ESTAB      0      0      10.10.9.67:27230              10.10.9.67:6443                users:(("kube-controller",pid=22104,fd=25))
ESTAB      0      0      10.10.9.67:27174              10.10.9.67:6443                users:(("kube-controller",pid=22104,fd=5))
ESTAB      0      0      10.10.9.67:27172              10.10.9.67:6443                users:(("kube-scheduler",pid=22099,fd=6))
ESTAB      0      0      10.10.9.67:27190              10.10.9.67:6443                users:(("kube-proxy",pid=22371,fd=9))

[root@tvm-01 ~]# ss -antp4 |grep ':6443'
ESTAB      0      0      10.10.9.68:65468              10.10.9.67:6443                users:(("kube-proxy",pid=11087,fd=5))
ESTAB      0      0      127.0.0.1:62230              127.0.0.1:6443                users:(("kube-apiserver",pid=27042,fd=73))
ESTAB      0      0      10.10.9.68:46188              10.10.9.68:6443                users:(("kubelet",pid=5107,fd=12))

[root@tvm-02 ~]# ss -antp4 |grep ':6443'
ESTAB      0      0      10.10.9.69:6926               10.10.9.67:6443                users:(("kube-proxy",pid=32456,fd=5))
ESTAB      0      0      10.10.9.69:59622              10.10.9.69:6443                users:(("kubelet",pid=27268,fd=10))
ESTAB      0      0      127.0.0.1:7328               127.0.0.1:6443                users:(("kube-apiserver",pid=15150,fd=73))
### 符合预期，上述 2 个节点的 kubelet 服务并未连接到 10.10.9.67:6443 （切换前的 apiserver 地址）
```
