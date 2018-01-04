# 使用kubeadm部署k8s集群09-配置worker节点
2018/1/4


### 配置 worker 节点
  - 初始化
  - 加入集群
  - 切换 worker 节点连接到 apiserver 的 LB 入口
  - 调整集群中节点角色和调度策略


##### 初始化
- /etc/hosts
```bash
### k8s master @envDev
10.10.9.67 tvm-00
10.10.9.68 tvm-01
10.10.9.69 tvm-02

### k8s worker @envDev
10.10.9.74 tvm-03
10.10.9.75 tvm-04

### k8s apiserver SLB
10.10.9.76 kubernetes.default.svc.cluster.local
```

- docker
```bash
yum -y install yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
yum -y install docker-ce-17.09.1.ce-1.el7.centos.x86_64
systemctl enable docker

mkdir -p /data2/docker
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "graph": "/data2/docker",
  "storage-driver": "overlay",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "registry-mirrors": ["https://xxx.mirror.aliyuncs.com"]
}
EOF
```

- k8s
```bash
cat <<'_EOF' >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
_EOF
sysctl --system


### worker 节点需要的镜像
docker load -i gcr.io-worker.tar
docker load -i calico-worker.tar

### worker 节点需要的 rpm 包
[root@tvm-03 ~]# cd ~/k8s_install/k8s_rpms_1.9
[root@tvm-03 k8s_rpms_1.9]# ls
kubelet-1.9.0-0.x86_64.rpm  kubernetes-cni-0.6.0-0.x86_64.rpm  socat-1.7.3.2-2.el7.x86_64.rpm

yum localinstall *.rpm -y
sed -i 's#--cgroup-driver=systemd#--cgroup-driver=cgroupfs#' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
```

##### 加入集群
```bash
### 在 mater 上重新生成 token （如果过期了的话）
kubeadm join --token 9db9dd.09bd5226fb3f259c 10.10.9.67:6443 --discovery-token-ca-cert-hash sha256:42cfdc412e731793ce2fa20aad1d8163ee8e6e5c05c30765f204ff086823c653

### 在 master 上查看节点是否加入
[root@tvm-00 ~]# kubectl get nodes
NAME                     STATUS    ROLES     AGE       VERSION
tvm-00   Ready     master    12d       v1.9.0
tvm-01   Ready     <none>    8d        v1.9.0
tvm-02   Ready     <none>    8d        v1.9.0
tvm-03   Ready     <none>    30m       v1.9.0
tvm-04   Ready     <none>    29m       v1.9.0
```

### 切换 worker 节点连接到 apiserver 的 LB 入口
```bash
sed -i 's#https://10.10.9.67:6443#https://kubernetes.default.svc.cluster.local:6443#' /etc/kubernetes/kubelet.conf
systemctl restart kubelet

### 验证一下
[root@tvm-03 k8s_install]# ss -antp4 |grep ':6443'
ESTAB      0      0      10.10.9.74:56118              10.10.9.76:6443                users:(("kubelet",pid=21260,fd=12))
ESTAB      0      0      10.10.9.74:53204              10.10.9.67:6443                users:(("kube-proxy",pid=15834,fd=5))

### 符合预期
```


##### 调整集群中节点角色和调度策略
```bash
### 当前状态
[root@tvm-00 ~]# kubectl describe nodes/tvm-00 |grep -E '(Roles|Taints)'
Roles:              master
Taints:             node-role.kubernetes.io/master:NoSchedule
[root@tvm-00 ~]# kubectl describe nodes/tvm-01 |grep -E '(Roles|Taints)'
Roles:              <none>
Taints:             <none>

### 设置 tvm-01 为 master 且不允许调度
[root@tvm-00 ~]# kubectl label node tvm-01 node-role.kubernetes.io/master=
node "tvm-01" labeled
[root@tvm-00 ~]# kubectl taint nodes tvm-01 node-role.kubernetes.io/master=:NoSchedule
node "tvm-01" tainted

### 符合预期
[root@tvm-00 ~]# kubectl describe nodes/tvm-01 |grep -E '(Roles|Taints)'
Roles:              master
Taints:             node-role.kubernetes.io/master:NoSchedule

### 设置 tvm-02 为 master 且不允许调度（操作类似，略）
[root@tvm-00 ~]# kubectl get nodes
NAME                     STATUS    ROLES     AGE       VERSION
tvm-00   Ready     master    12d       v1.9.0
tvm-01   Ready     master    8d        v1.9.0
tvm-02   Ready     master    8d        v1.9.0
tvm-03   Ready     <none>    1h        v1.9.0
tvm-04   Ready     <none>    1h        v1.9.0


```



### ZYXW、参考
1. [Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
