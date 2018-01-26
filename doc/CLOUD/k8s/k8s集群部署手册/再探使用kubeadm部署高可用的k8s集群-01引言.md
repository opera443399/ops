# 再探使用kubeadm部署高可用的k8s集群-01引言
2018/1/26


### 提示
仅供测试用途
前言：
高可用一直是重要的话题，需要持续研究。
最近关注到 k8s 官网文档有更新，其中一篇部署高可用集群的文章思路不错，简洁给力，希望能分享给有需要的小伙伴一起研究下。


### 资源
* k8s node
  - master0, 10.222.0.100
  - master1, 10.222.0.101
  - master2, 10.222.0.102
  - LB, 10.222.0.88
    - master0, master1, master2
* k8s version
  - v1.9.0
* 步骤
  - 部署 etcd 集群
  - 配置 k8s master
  - 配置 k8s worker


### 部署 etcd 集群
* 有2种方式可供选择
  - 在 3 个独立的 vm 上部署
  - 复用 3 个 k8s master 节点（本文）

* 基本步骤
  - 准备工作
  - 创建 etcd CA 证书
  - 创建 etcd client 证书
  - 同步 ca 和 client 的证书相关文件到另外 2 个节点
  - 创建 server 和 peer 证书（所有节点上操作）
  - 创建 etcd 服务（所有节点上操作）


##### 准备工作
```bash
##### 配置节点之间的 ssh 登录（略）
##### 准备工具 cfssl 和 cfssljson
curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /usr/local/bin/cfssl*

##### 后续将用到的变量
export PEER_NAME=$(hostname)
export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')


```


##### 创建 etcd CA 证书
```bash
##### 在 master0 上操作
mkdir -p /etc/kubernetes/pki/etcd
cd !$

cat >ca-config.json <<EOL
{
    "signing": {
        "default": {
            "expiry": "43800h"
        },
        "profiles": {
            "server": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            },
            "client": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOL

cat >ca-csr.json <<EOL
{
    "CN": "etcd",
    "key": {
        "algo": "rsa",
        "size": 2048
    }
}
EOL

##### 生成 CA 证书
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

##### 输出
ca.pem
ca-key.pem

```


##### 创建 etcd client 证书
```bash
cat >client.json <<EOL
{
    "CN": "client",
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
EOL

##### 生成 client 证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client

##### 输出
client.pem
client-key.pem

```

##### 同步 ca 和 client 的证书相关文件到另外 2 个节点
```bash
mkdir -p /etc/kubernetes/pki/etcd
cd !$

scp root@10.222.0.100:/etc/kubernetes/pki/etcd/ca.pem .
scp root@10.222.0.100:/etc/kubernetes/pki/etcd/ca-key.pem .
scp root@10.222.0.100:/etc/kubernetes/pki/etcd/ca-config.json .
scp root@10.222.0.100:/etc/kubernetes/pki/etcd/client.pem .
scp root@10.222.0.100:/etc/kubernetes/pki/etcd/client-key.pem .



scp root@10.222.0.100:/usr/local/bin/cfssl* /usr/local/bin/
```

##### 创建 server 和 peer 证书（所有节点上操作）
```bash
cfssl print-defaults csr > config.json
sed -i '0,/CN/{s/example\.net/'"$PEER_NAME"'/}' config.json
sed -i 's/www\.example\.net/'"$PRIVATE_IP"'/' config.json
sed -i 's/example\.net/'"$PEER_NAME"'/' config.json

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server config.json | cfssljson -bare server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer config.json | cfssljson -bare peer

```

#### 创建 etcd 服务（所有节点上操作）
```bash
##### 下载 etcd 和 etcdctl
export ETCD_VERSION=v3.1.10
curl -sSL https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz | tar -xzv --strip-components=1 -C /usr/local/bin/
rm -rf etcd-$ETCD_VERSION-linux-amd64*

##### 准备 etcd 服务依赖的环境变量
touch /etc/etcd.env
echo "PEER_NAME=$PEER_NAME" >> /etc/etcd.env
echo "PRIVATE_IP=$PRIVATE_IP" >> /etc/etcd.env

##### 准备 etcd 服务的配置文件
cat >/etc/systemd/system/etcd.service <<EOL
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
EnvironmentFile=/etc/etcd.env
Type=notify
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/usr/local/bin/etcd --name ${PEER_NAME} \
    --data-dir /var/lib/etcd \
    --listen-client-urls https://${PRIVATE_IP}:2379 \
    --advertise-client-urls https://${PRIVATE_IP}:2379 \
    --listen-peer-urls https://${PRIVATE_IP}:2380 \
    --initial-advertise-peer-urls https://${PRIVATE_IP}:2380 \
    --cert-file=/etc/kubernetes/pki/etcd/server.pem \
    --key-file=/etc/kubernetes/pki/etcd/server-key.pem \
    --client-cert-auth \
    --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \
    --peer-cert-file=/etc/kubernetes/pki/etcd/peer.pem \
    --peer-key-file=/etc/kubernetes/pki/etcd/peer-key.pem \
    --peer-client-cert-auth \
    --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \
    --initial-cluster master0=https://10.222.0.100:2380,master1=https://10.222.0.101:2380,master2=https://10.222.0.102:2380 \
    --initial-cluster-token my-etcd-token \
    --initial-cluster-state new

[Install]
WantedBy=multi-user.target

EOL

##### 激活 etcd 服务
systemctl daemon-reload
systemctl enable etcd

##### 启动
systemctl start etcd
systemctl status etcd

##### 备份证书
mkdir ~/k8s_install/master/init
cd !$
cp -a /etc/kubernetes/pki/etcd .

```

### 配置 k8s master

##### 初始化 master0
```bash
cat >config.yaml <<EOL
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
api:
  advertiseAddress: 10.222.0.100
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


kubeadm init --config=config.yaml
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

```



##### 初始化 master1 master2
```bash
##### 同步在 master0 上生成的 ca.crt 和 ca.key 文件
scp /etc/kubernetes/pki/ca.* 10.222.0.101:/etc/kubernetes/pki/
scp /etc/kubernetes/pki/ca.* 10.222.0.102:/etc/kubernetes/pki/

##### 参考初始化 master0 时的操作来初始化 master1 和 master2

```


### 配置 k8s worker

##### 初始化 worker（此步骤开始遇到异常！节点未加入集群，提示未授权访问 apiserver 服务，可能需要新的 kubeadm 版本？姿势不对？待后续实验后继续更新，懒得去 github 上讨论了，路过的有心人不妨试试）
```bash
##### 如果是重复操作，请先 reset
[root@worker01 ~]# kubeadm reset
[preflight] Running pre-flight checks.
[reset] Stopping the kubelet service.
[reset] Unmounting mounted directories in "/var/lib/kubelet"
[reset] Removing kubernetes-managed containers.
[reset] No etcd manifest found in "/etc/kubernetes/manifests/etcd.yaml". Assuming external etcd.
[reset] Deleting contents of stateful directories: [/var/lib/kubelet /etc/cni/net.d /var/lib/dockershim /var/run/kubernetes]
[reset] Deleting contents of config directories: [/etc/kubernetes/manifests /etc/kubernetes/pki]
[reset] Deleting files: [/etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf]
[root@worker01 ~]#

##### 将 worker 节点加入集群：
[root@worker01 ~]# kubeadm join --token xxx 10.222.0.102:6443 --discovery-token-ca-cert-hash sha256:xxx
[preflight] Running pre-flight checks.
        [WARNING SystemVerification]: docker version is greater than the most recently validated version. Docker version: 17.09.1-ce. Max validated version: 17.03
        [WARNING FileExisting-crictl]: crictl not found in system path
[preflight] Starting the kubelet service
[discovery] Trying to connect to API Server "10.222.0.102:6443"
[discovery] Created cluster-info discovery client, requesting info from "https://10.222.0.102:6443"
[discovery] Requesting info from "https://10.222.0.102:6443" again to validate TLS against the pinned public key
[discovery] Cluster info signature and contents are valid and TLS certificate validates against pinned roots, will use API Server "10.222.0.102:6443"
[discovery] Successfully established connection with API Server "10.222.0.102:6443"

This node has joined the cluster:
* Certificate signing request was sent to master and a response
  was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the master to see this node join the cluster.


##### 通常看到上述输出，会以为没问题来，实际上，在 master 上 kubectl get nodes 时，却看不到 worker 节点加入到集群中，此时去查看日志：
[root@worker01 ~]# date
Thu Jan 25 09:09:12 CST 2018
[root@worker01 ~]# journalctl -u kubelet -S '2018-01-25 09:0'
-- Logs begin at Tue 2017-10-31 23:40:50 CST, end at Thu 2018-01-25 09:09:27 CST. --
Jan 25 09:09:03 worker01 systemd[1]: Started kubelet: The Kubernetes Node Agent.
Jan 25 09:09:03 worker01 systemd[1]: Starting kubelet: The Kubernetes Node Agent...
Jan 25 09:09:03 worker01 kubelet[4808]: I0125 09:09:03.693518    4808 feature_gate.go:220] feature gates: &{{} map[]}
Jan 25 09:09:03 worker01 kubelet[4808]: I0125 09:09:03.693607    4808 controller.go:114] kubelet config controller: starting controller
Jan 25 09:09:03 worker01 kubelet[4808]: I0125 09:09:03.693622    4808 controller.go:118] kubelet config controller: validating combination of defaults and flags
Jan 25 09:09:04 worker01 kubelet[4808]: W0125 09:09:04.012780    4808 cni.go:171] Unable to update cni config: No networks found in /etc/cni/net.d
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.016411    4808 server.go:182] Version: v1.9.0
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.016467    4808 feature_gate.go:220] feature gates: &{{} map[]}
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.016603    4808 plugins.go:101] No cloud provider specified.
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.072301    4808 certificate_store.go:130] Loading cert/key pair from ("/var/lib/kubelet/pki/kubelet-client.crt", "/var/lib/kubelet/pki/kubelet-clie
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.170082    4808 server.go:428] --cgroups-per-qos enabled, but --cgroup-root was not specified.  defaulting to /
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.170355    4808 container_manager_linux.go:242] container manager verified user specified cgroup-root exists: /
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.170368    4808 container_manager_linux.go:247] Creating Container Manager object based on Node Config: {RuntimeCgroupsName: SystemCgroupsName: Kub
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.170489    4808 container_manager_linux.go:266] Creating device plugin manager: false
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.170575    4808 kubelet.go:290] Adding manifest path: /etc/kubernetes/manifests
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.170602    4808 kubelet.go:313] Watching apiserver
Jan 25 09:09:04 worker01 kubelet[4808]: E0125 09:09:04.172499    4808 file.go:76] Unable to read manifest path "/etc/kubernetes/manifests": path does not exist, ignoring
Jan 25 09:09:04 worker01 kubelet[4808]: W0125 09:09:04.174534    4808 kubelet_network.go:139] Hairpin mode set to "promiscuous-bridge" but kubenet is not enabled, falling back to "hairpin-veth"
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.174567    4808 kubelet.go:571] Hairpin mode set to "hairpin-veth"
Jan 25 09:09:04 worker01 kubelet[4808]: W0125 09:09:04.174646    4808 cni.go:171] Unable to update cni config: No networks found in /etc/cni/net.d
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.174691    4808 client.go:80] Connecting to docker on unix:///var/run/docker.sock
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.174704    4808 client.go:109] Start docker client with request timeout=2m0s
Jan 25 09:09:04 worker01 kubelet[4808]: W0125 09:09:04.176446    4808 cni.go:171] Unable to update cni config: No networks found in /etc/cni/net.d
Jan 25 09:09:04 worker01 kubelet[4808]: W0125 09:09:04.178886    4808 cni.go:171] Unable to update cni config: No networks found in /etc/cni/net.d
Jan 25 09:09:04 worker01 kubelet[4808]: I0125 09:09:04.178938    4808 docker_service.go:232] Docker cri networking managed by cni
Jan 25 09:09:04 worker01 kubelet[4808]: E0125 09:09:04.191260    4808 reflector.go:205] k8s.io/kubernetes/pkg/kubelet/kubelet.go:465: Failed to list *v1.Service: Unauthorized
Jan 25 09:09:04 worker01 kubelet[4808]: E0125 09:09:04.191347    4808 reflector.go:205] k8s.io/kubernetes/pkg/kubelet/kubelet.go:474: Failed to list *v1.Node: Unauthorized
Jan 25 09:09:04 worker01 kubelet[4808]: E0125 09:09:04.191438    4808 reflector.go:205] k8s.io/kubernetes/pkg/kubelet/config/apiserver.go:47: Failed to list *v1.Pod: Unauthorized



##### 注意到没：Unauthorized
##### 未找到解决办法

```

##### 在 master 上更新 kube-proxy（注明：上一个步骤未完成，下述内容待验证）
```bash
kubectl get configmap -n kube-system kube-proxy -o yaml > kube-proxy.yaml
sed -i 's#server:.*#server: https://10.222.0.88:6443#g' kube-proxy.yaml
kubectl apply -f kube-proxy.yaml --force
kubectl delete pod -n kube-system -l k8s-app=kube-proxy


##### 更新 worker 上 kubelet 服务
sed -i 's#server:.*#server: https://10.222.0.88:6443#g' /etc/kubernetes/kubelet.conf
systemctl restart kubelet


##### 思考一个 LB 相关的问题：
当前状态：
LB -> k8s_master(m0,m1,m2)
kube-proxy -> m0

如果将 kube-proxy 的 apiserver 切到 LB 则：
kube-proxy -> LB

此时 client 访问 k8s 中的容器时，数据流量可能场景：
client(xx) -> m1_ip_port -> kube-proxy(m0) -> container
                            -> apiserver(LB/m0)
也就是说：
kube-proxy(m0) -> apiserver(m0)

上述场景，如果是 LVS/DR 模式的 LB 则会有异常
RS1 -> LB1 -> RS1
导致：
RS1 -> RS1

此时可以考虑在中间增加一层 LB
RS2 -> LB2 -> HAProxy -> RS2
变成：
RS2 -> HAProxy -> RS2

```


### ZYXW、参考
1. [Creating HA clusters with kubeadm](https://kubernetes.io/docs/setup/independent/high-availability/)
