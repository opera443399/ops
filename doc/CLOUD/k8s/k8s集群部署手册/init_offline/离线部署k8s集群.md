# 离线部署k8s集群
2018/2/23

### 目录结构
```bash
[root@master-100 k8s_install]# pwd
/root/k8s_install
[root@master-100 k8s_install]# tree .
.
├── init_offline
│   ├── etcd-server-init.sh
│   ├── etcd-server-key-init.sh
│   ├── gcr.io
│   │   ├── gcr.io-all.tar
│   │   └── gcr.io-worker.tar
│   ├── init-hosts.sh
│   ├── init-master.sh
│   ├── init-worker.sh
│   └── k8s_rpms_1.9
│       ├── kubeadm-1.9.0-0.x86_64.rpm
│       ├── kubectl-1.9.0-0.x86_64.rpm
│       ├── kubelet-1.9.0-0.x86_64.rpm
│       ├── kubernetes-cni-0.6.0-0.x86_64.rpm
│       ├── README.md
│       └── socat-1.7.3.2-2.el7.x86_64.rpm
├── master
│   └── init
│       ├── config.yaml
│       └── etcd
│           ├── ca-config.json
│           ├── ca.csr
│           ├── ca-csr.json
│           ├── ca-key.pem
│           ├── ca.pem
│           ├── client.csr
│           ├── client.json
│           ├── client-key.pem
│           ├── client.pem
│           ├── config.json
│           ├── peer.csr
│           ├── peer-key.pem
│           ├── peer.pem
│           ├── server.csr
│           ├── server-key.pem
│           └── server.pem
└── network
    └── calico
        ├── calico-v2.6.tar
        └── calico-v2.6.yaml

8 directories, 32 files

```


### 配置 hosts, docker, k8s 服务
```bash
##### 在所有 master 节点执行
sh init-hosts.sh
sh init-master.sh

##### 在所有 worker 节点执行
sh init-hosts.sh
sh init-worker.sh

```


### 配置 etcd 集群
```bash
##### 在 master-100 上执行
sh etcd-server-key-init.sh
##### 在所有 master 节点执行
sh etcd-server-init.sh

##### 启动
systemctl start etcd
systemctl status etcd

##### 测试
etcdctl --endpoints="https://10.222.0.100:2379" --ca-file=/etc/kubernetes/pki/etcd/ca.pem --cert-file=/etc/kubernetes/pki/etcd/client.pem --key-file=/etc/kubernetes/pki/etcd/client-key.pem member list

```

### 初始化 master-101
```bash
mkdir -p ~/k8s_install/master/init
cd ~/k8s_install/master/init

##### 备份 etcd 证书
cp -a /etc/kubernetes/pki/etcd ~/k8s_install/master/init/
##### 后续如果 kubeadm reset 将导致 pki 目录被清空，此时可以恢复证书
cp -a ~/k8s_install/master/init/etcd /etc/kubernetes/pki/

##### 准备配置用于初始化
export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')

cat >config.yaml <<EOL
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
api:
  advertiseAddress: ${PRIVATE_IP}
etcd:
  endpoints:
  - https://10.222.0.100:2379
  - https://10.222.0.101:2379
  - https://10.222.0.102:2379
  caFile: /etc/kubernetes/pki/etcd/ca.pem
  certFile: /etc/kubernetes/pki/etcd/client.pem
  keyFile: /etc/kubernetes/pki/etcd/client-key.pem
networking:
  podSubnet: 172.30.0.0/16
apiServerCertSANs:
- 10.222.0.88
kubernetesVersion: v1.9.0
apiServerExtraArgs:
  endpoint-reconciler-type: lease
EOL

##### 开始初始化 master
kubeadm init --config=config.yaml

##### 使用 kubectl
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

```

### 初始化 网络插件之 calico
```bash
##### 关于 calico 的更多内容，请参考笔记：使用kubeadm部署k8s集群01-初始化
mkdir -p ~/k8s_install/network/calico
cd ~/k8s_install/network/calico
##### 导入提前准备好的镜像
docker load -i calico-v2.6.tar
##### 注意 CALICO_IPV4POOL_CIDR 是否和 podSubnet 一致，默认的需要替换：
sed -i 's#192.168.0.0/16#172.30.0.0/16#' calico-v2.6.yaml
##### 启用
kubectl apply -f calico-v2.6.yaml

```

### 初始化 master-101 master-102
```bash
##### 将 master-101 加入集群（ 因 master-102 的操作同理，略过）
##### 同步在 master-100 上生成的 ca.crt 和 ca.key 文件
scp 10.222.0.100:/etc/kubernetes/pki/ca.* /etc/kubernetes/pki

##### 重复 初始化 master-100 的操作即可

```


### 配置 k8s worker
```bash
##### 加入集群
kubeadm join --token xxx.xxxxxxx 10.222.0.100:6443 --discovery-token-ca-cert-hash sha256:xxx

```


### 查看状态
```bash
kubectl get ds,deploy,svc,pods --all-namespaces
kubectl get nodes

```
