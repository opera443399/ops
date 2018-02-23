# 使用kubeadm部署k8s集群01-初始化
2018/2/23

### 节点配置
  - master x3

### OS
  - version: centos7
##### swapoff
```bash
### 阿里云默认：off
```

##### hosts
```bash
### 每个节点上配置：
[root@tvm-00 ~]# cat /etc/hosts
### k8s master @envDev
10.10.9.67 tvm-00
10.10.9.68 tvm-01
10.10.9.69 tvm-02

```


### Docker
  - version: latest(17.09.1-ce)

##### 安装
```bash
### 安装
[root@tvm-00 ~]# yum -y install yum-utils
[root@tvm-00 ~]# yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
[root@tvm-00 ~]# yum makecache fast
### 可以直接 yum -y install docker-ce 来安装，但如果要保持版本一致，应该指定完整的包名，例如：
[root@tvm-00 ~]# yum -y install docker-ce-17.09.1.ce-1.el7.centos.x86_64

### 个性化配置
[root@tvm-00 ~]# mkdir -p /data/docker
[root@tvm-00 ~]# mkdir -p /etc/docker; tee /etc/docker/daemon.json <<-'EOF'
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "graph": "/data/docker",
  "storage-driver": "overlay",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "registry-mirrors": ["https://xxx.mirror.aliyuncs.com"]
}
EOF


### 注意：此处设置了 docker 的 cgroupdriver 和 k8s 保持一致
### 参考文档：#2,#3（文末）

[root@tvm-00 ~]# systemctl daemon-reload && systemctl enable docker && systemctl start docker
```


### 镜像
##### registry mirror
- 在阿里云上开通容器镜像服务后，可以找到一个专属的加速地址
  - 已经在上一步配置 docker 时使用

##### kubeadm 需要下述镜像
- 提前 pull 到本地，如果网络慢，可考虑通过 docker save && docker load 操作分发镜像到各节点
```bash
### 针对下述镜像：
gcr.io/google_containers/kube-apiserver-amd64:v1.9.0
gcr.io/google_containers/kube-controller-manager-amd64:v1.9.0
gcr.io/google_containers/kube-scheduler-amd64:v1.9.0
gcr.io/google_containers/kube-proxy-amd64:v1.9.0
gcr.io/google_containers/etcd-amd64:3.1.10
gcr.io/google_containers/pause-amd64:3.0
gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.7
gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.7
gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.7

### 制作 master 节点用的 image 压缩包
[root@tvm-00 ~]# cd ~/k8s_install/master/gcr.io
[root@tvm-00 gcr.io]# docker save -o gcr.io-all.tar \
gcr.io/google_containers/kube-apiserver-amd64:v1.9.0 \
gcr.io/google_containers/kube-controller-manager-amd64:v1.9.0 \
gcr.io/google_containers/kube-scheduler-amd64:v1.9.0 \
gcr.io/google_containers/kube-proxy-amd64:v1.9.0 \
gcr.io/google_containers/etcd-amd64:3.1.10 \
gcr.io/google_containers/pause-amd64:3.0 \
gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.7 \
gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.7 \
gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.7

### 制作 worker 节点用的 image 压缩包
[root@tvm-00 gcr.io]# docker save -o gcr.io-worker.tar \
gcr.io/google_containers/kube-proxy-amd64:v1.9.0 \
gcr.io/google_containers/pause-amd64:3.0

[root@tvm-00 gcr.io]# ls
gcr.io-all.tar  gcr.io-worker.tar

### 同步到目标节点后，导入镜像：
[root@tvm-00 ~]# docker load -i gcr.io-all.tar
[root@tvm-00 ~]# docker load -i gcr.io-worker.tar
```

##### private registry
  - 使用阿里云镜像服务


### 准备好配置 k8s 集群所需的基础服务
  - version: 1.9.0
  - 所有节点安装 kubelet kubeadm kubectl 这3个服务
    - 参考文档：#2（文末）
##### 系统配置调整
```bash
### 禁用SELinux
[root@tvm-00 ~]# getenforce
Disabled
### 如果不是 Disabled 则：
[root@tvm-00 ~]# setenforce 0

### 系统参数
[root@tvm-00 ~]# cat <<'_EOF' >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
_EOF
[root@tvm-00 ~]# sysctl --system
```

##### 下载 rpm 包后本地安装
  - 因为墙的存在，你懂的。当然了，最好你拥有自己的本地 yum 源来缓存这些包
```bash
### 安装
[root@tvm-00 ~]# cd ~/k8s_install/k8s_rpms_1.9
[root@tvm-00 k8s_rpms_1.9]# ls
k8s/kubeadm-1.9.0-0.x86_64.rpm  k8s/kubectl-1.9.0-0.x86_64.rpm  k8s/kubelet-1.9.0-0.x86_64.rpm  k8s/kubernetes-cni-0.6.0-0.x86_64.rpm  k8s/socat-1.7.3.2-2.el7.x86_64.rpm

[root@tvm-00 k8s_rpms_1.9]# yum localinstall *.rpm -y

[root@tvm-00 k8s_rpms_1.9]# systemctl enable kubelet
```

##### cgroupfs vs systemd
  - 参考文档：#3（文末）
```bash
### 调整 --cgroup-driver 来适配 docker 服务默认采用的 cgroupfs 驱动：
[root@tvm-00 ~]# sed -i 's#--cgroup-driver=systemd#--cgroup-driver=cgroupfs#' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
[root@tvm-00 ~]# systemctl daemon-reload


###### 因为，在 centos7 上使用 --cgroup-driver=systemd 将导致后续 kube-dns 服务异常，实例：
### （容器 kubedns 异常的实例）
[root@tvm-00 ~]# kubectl logs -n kube-system --tail=20 kube-dns-6f4fd4bdf-ntcgn -c kubedns
container_linux.go:265: starting container process caused "process_linux.go:284: applying cgroup configuration for process caused \"No such device or address\""
### （容器 sidecar 异常）
[root@tvm-00 ~]# kubectl logs -n kube-system --tail=1 kube-dns-6f4fd4bdf-ntcgn -c sidecar
W1226 06:21:40.170896       1 server.go:64] Error getting metrics from dnsmasq: read udp 127.0.0.1:44903->127.0.0.1:53: read: connection refused
### （容器 dnsmasq 无异常）
[root@tvm-00 ~]# kubectl logs -n kube-system --tail=20 kube-dns-6f4fd4bdf-ntcgn -c dnsmasq
I1226 06:21:40.214148       1 main.go:76] opts: {{/usr/sbin/dnsmasq [-k --cache-size=1000 --no-negcache --log-facility=- --server=/cluster.local/127.0.0.1#10053 --server=/in-addr.arpa/127.0.0.1#10053 --server=/ip6.arpa/127.0.0.1#10053] true} /etc/k8s/dns/dnsmasq-nanny 10000000000}
I1226 06:21:40.214233       1 nanny.go:94] Starting dnsmasq [-k --cache-size=1000 --no-negcache --log-facility=- --server=/cluster.local/127.0.0.1#10053 --server=/in-addr.arpa/127.0.0.1#10053 --server=/ip6.arpa/127.0.0.1#10053]
I1226 06:21:40.222440       1 nanny.go:119]
W1226 06:21:40.222453       1 nanny.go:120] Got EOF from stdout
I1226 06:21:40.222537       1 nanny.go:116] dnsmasq[9]: started, version 2.78 cachesize 1000
### （输出略）
```



### 初始化 k8s 集群
  - 初始化前
  - 如果报错，请参考 reset 文档
  - 执行初始化
  - 查看 k8s 集群的信息
  - 附加组件之 network plugins - calico
    - 要先传递 --pod-network-cidr 给 kubeadm init
    - 要配置网段 CALICO_IPV4POOL_CIDR
    -
##### 初始化前
```bash
### 注意1：因为是离线安装，参数中指定了版本
--kubernetes-version=v1.9.0
### 注意2：指定了 CIDR 是因为后续要使用的网络组件为 calico 需要先定义好网段来避免未来可能的冲突（后续定义 calico 配置时还会用到这个网段）
--pod-network-cidr=172.30.0.0/20

### 下述 IP 地址池满足小型集群的需求
### 网段: 172.30.0.0/20
### 主机列表: 172.30.0.1 - 172.30.15.254 = 4094 个
```

##### 如果报错，请参考 reset 文档
  - 参考文档：#4（文末）
```bash
[root@tvm-00 ~]# kubeadm reset
[preflight] Running pre-flight checks.
[reset] Stopping the kubelet service.
[reset] Unmounting mounted directories in "/var/lib/kubelet"
[reset] Removing kubernetes-managed containers.
[reset] Deleting contents of stateful directories: [/var/lib/kubelet /etc/cni/net.d /var/lib/dockershim /var/run/kubernetes /var/lib/etcd]
[reset] Deleting contents of config directories: [/etc/kubernetes/manifests /etc/kubernetes/pki]
[reset] Deleting files: [/etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf]
```

##### 执行初始化
```bash
[root@tvm-00 ~]# kubeadm init --pod-network-cidr=172.30.0.0/20 --kubernetes-version=v1.9.0
[init] Using Kubernetes version: v1.9.0
[init] Using Authorization modes: [Node RBAC]
[preflight] Running pre-flight checks.
        [WARNING SystemVerification]: docker version is greater than the most recently validated version. Docker version: 17.09.1-ce. Max validated version: 17.03
        [WARNING FileExisting-crictl]: crictl not found in system path
[preflight] Starting the kubelet service
[certificates] Generated ca certificate and key.
[certificates] Generated apiserver certificate and key.
[certificates] apiserver serving cert is signed for DNS names [tvm-00 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.10.9.67]
[certificates] Generated apiserver-kubelet-client certificate and key.
[certificates] Generated sa key and public key.
[certificates] Generated front-proxy-ca certificate and key.
[certificates] Generated front-proxy-client certificate and key.
[certificates] Valid certificates and keys now exist in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "controller-manager.conf"
[kubeconfig] Wrote KubeConfig file to disk: "scheduler.conf"
[controlplane] Wrote Static Pod manifest for component kube-apiserver to "/etc/kubernetes/manifests/kube-apiserver.yaml"
[controlplane] Wrote Static Pod manifest for component kube-controller-manager to "/etc/kubernetes/manifests/kube-controller-manager.yaml"
[controlplane] Wrote Static Pod manifest for component kube-scheduler to "/etc/kubernetes/manifests/kube-scheduler.yaml"
[etcd] Wrote Static Pod manifest for a local etcd instance to "/etc/kubernetes/manifests/etcd.yaml"
[init] Waiting for the kubelet to boot up the control plane as Static Pods from directory "/etc/kubernetes/manifests".
### （输出略）
Your Kubernetes master has initialized successfully!
```

##### 查看 k8s 集群的信息
```bash
### 为了方便执行 kubectl 指令，需要如下操作：
[root@tvm-00 ~]# mkdir -p $HOME/.kube
[root@tvm-00 ~]# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
### 查看节点信息：
[root@tvm-00 ~]# kubectl get nodes
NAME     STATUS     ROLES     AGE       VERSION
tvm-00   NotReady   master    19h       v1.9.0
### 查看日志：
[root@tvm-00 ~]# journalctl -xeu kubelet
### 查看集群信息：
[root@tvm-00 ~]# kubectl cluster-info
Kubernetes master is running at https://10.10.9.67:6443
KubeDNS is running at https://10.10.9.67:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

##### 附加组件之 network plugins - calico
- 准备 calico 需要的下述镜像
  - 提前 pull 到本地，在 worker 节点上也需要 node 和 cni 这2个镜像
```bash
### 准备 calico.yaml 配置文件
[root@tvm-00 ~]# mkdir -p ~/k8s_install/master/network
[root@tvm-00 ~]# cd !$
[root@tvm-00 network]# curl -so calico-v2.6.yaml  https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml

[root@tvm-00 network]# grep image calico-v2.6.yaml |uniq |sed -e 's#^.*image: quay.io#docker pull quay.io#g'
docker pull quay.io/coreos/etcd:v3.1.10
docker pull quay.io/calico/node:v2.6.5
docker pull quay.io/calico/cni:v1.11.2
docker pull quay.io/calico/kube-controllers:v1.0.2


### 可以将镜像保存下来，拷贝到其他节点上直接 docker load -i xxx.tar 即可
[root@tvm-00 network]# docker save -o calico-all.tar quay.io/coreos/etcd:v3.1.10 quay.io/calico/node:v2.6.5 quay.io/calico/cni:v1.11.2 quay.io/calico/kube-controllers:v1.0.2
[root@tvm-00 network]# ls
calico-all.tar  calico-v2.6.yaml
```

- 部署 calico
```bash
### 更新 calico.yaml 配置文件
[root@tvm-00 network]# sed -i 's#192.168.0.0/16#172.30.0.0/20#' calico-v2.6.yaml

### 部署
[root@tvm-00 network]# kubectl apply -f calico-v2.6.yaml
configmap "calico-config" created
daemonset "calico-etcd" created
service "calico-etcd" created
daemonset "calico-node" created
deployment "calico-kube-controllers" created
deployment "calico-policy-controller" created
clusterrolebinding "calico-cni-plugin" created
clusterrole "calico-cni-plugin" created
serviceaccount "calico-cni-plugin" created
clusterrolebinding "calico-kube-controllers" created
clusterrole "calico-kube-controllers" created
serviceaccount "calico-kube-controllers" created

### 确认 kube-dns pod is Running
[root@tvm-00 ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                             READY     STATUS    RESTARTS   AGE
kube-system   calico-etcd-djrtb                                1/1       Running   1          1d
kube-system   calico-kube-controllers-d6c6b9b8-7ssrn           1/1       Running   1          1d
kube-system   calico-node-mff7x                                2/2       Running   3          1d
kube-system   etcd-tvm-00                                      1/1       Running   1          4h
kube-system   kube-apiserver-tvm-00                            1/1       Running   0          2m
kube-system   kube-controller-manager-tvm-00                   1/1       Running   2          3d
kube-system   kube-dns-6f4fd4bdf-ntcgn                         3/3       Running   7          3d
kube-system   kube-proxy-pfmh8                                 1/1       Running   1          3d
kube-system   kube-scheduler-tvm-00                            1/1       Running   2          3d

### 确认集群 nodes 的状态
[root@tvm-00 ~]# kubectl get nodes
NAME     STATUS    ROLES     AGE       VERSION
tvm-00   Ready     master    2d        v1.9.0
```

##### 将另外 2 个节点加入 k8s 集群
- kubeadm token
```bash
### 注意：kubeadm init 输出的 join 指令中 token 只有 24h 的有效期，如果过期后，需要重新生成，具体请参考：
[root@tvm-00 ~]# kubeadm token create --print-join-command
kubeadm join --token 84d7d1.e4ed7451c620436e 10.10.9.67:6443 --discovery-token-ca-cert-hash sha256:42cfdc412e731793ce2fa20aad1d8163ee8e6e5c05c30765f204ff086823c653

[root@tvm-00 ~]# kubeadm token list
TOKEN                     TTL       EXPIRES                     USAGES                   DESCRIPTION   EXTRA GROUPS
84d7d1.e4ed7451c620436e   23h       2017-12-26T14:46:16+08:00   authentication,signing   <none>        system:bootstrappers:kubeadm:default-node-token
```

- kubeadm join
```bash
[root@tvm-00 ~]# kubeadm join --token 84d7d1.e4ed7451c620436e 10.10.9.67:6443 --discovery-token-ca-cert-hash sha256:42cfdc412e731793ce2fa20aad1d8163ee8e6e5c05c30765f204ff086823c653
```

- 查看 cluster 信息
```bash
[root@tvm-00 ~]# kubectl get nodes
NAME     STATUS    ROLES     AGE       VERSION
tvm-00   Ready     master    3d        v1.9.0
tvm-01   Ready     <none>    2h        v1.9.0
tvm-02   Ready     <none>    27s       v1.9.0

[root@tvm-00 ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                             READY     STATUS    RESTARTS   AGE
kube-system   calico-etcd-djrtb                                1/1       Running   1          1d
kube-system   calico-kube-controllers-d6c6b9b8-7ssrn           1/1       Running   1          1d
kube-system   calico-node-9bncs                                2/2       Running   4          19h
kube-system   calico-node-mff7x                                2/2       Running   3          1d
kube-system   calico-node-mw96v                                2/2       Running   3          19h
kube-system   etcd-tvm-00                                      1/1       Running   1          4h
kube-system   kube-apiserver-tvm-00                            1/1       Running   0          2m
kube-system   kube-controller-manager-tvm-00                   1/1       Running   2          3d
kube-system   kube-dns-6f4fd4bdf-ntcgn                         3/3       Running   7          3d
kube-system   kube-proxy-6nqwv                                 1/1       Running   1          19h
kube-system   kube-proxy-7xtv4                                 1/1       Running   1          19h
kube-system   kube-proxy-pfmh8                                 1/1       Running   1          3d
kube-system   kube-scheduler-tvm-00                            1/1       Running   2          3d

### 符合预期，有 3 个 calico-node 和 kube-proxy 在集群中
```



### ZYXW、参考
1. [一步步打造基于Kubeadm的高可用Kubernetes集群-第一部分](http://tonybai.com/2017/05/15/setup-a-ha-kubernetes-cluster-based-on-kubeadm-part1/)
2. [install docker for kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/#installing-docker)
3. [kube-dns crashloopbackoff after flannel/weave install #54910](https://github.com/kubernetes/kubernetes/issues/54910)
4. [kubeadm reset](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#tear-down)
