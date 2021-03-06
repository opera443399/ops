# 再探使用kubeadm部署高可用的k8s集群-01引言
2018/4/24


### 提示
仅供测试用途
前言：
高可用一直是重要的话题，需要持续研究。
最近关注到 k8s 官网文档有更新，其中一篇部署高可用集群的文章思路不错，简洁给力，希望能分享给有需要的小伙伴一起研究下。


### 资源
* k8s node
  - master-100, 10.222.0.100
  - master-101, 10.222.0.101
  - master-102, 10.222.0.102
  - LB, 10.222.0.88
    - master-100, master-101, master-102
  - worker-201, 10.222.0.201
  - worker-202, 10.222.0.202
* k8s version
  - v1.9.0
* 步骤
  - 配置 hosts, docker, k8s 服务
  - 部署 etcd 集群
  - 配置 k8s master
  - 配置 k8s worker

* 附加
  - 网络
  - 在 master 上更新 kube-proxy（注明：未完成，下述内容待验证）


### 部署 etcd 集群
* 有2种方式可供选择
  - 在 3 个独立的 vm 上部署
  - 复用 3 个 k8s master 节点（本文）
    - 配置 hosts
    - 配置 docker 访问
    - 安装 k8s 服务


* 基本步骤
  - 准备工作
  - 创建 etcd CA 证书
  - 创建 etcd client 证书
  - 同步 ca 和 client 的证书相关文件到另外 2 个节点
  - 创建 server 和 peer 证书（所有节点上操作）
  - 创建 etcd 服务对应到 systemd 配置（所有节点上操作）


##### 准备工作
```bash
##### 配置节点之间的 ssh 登录（略）
##### 准备 docker, k8s 相关的 rpm 包 和镜像（略）
> 使用kubeadm部署k8s集群00-缓存gcr.io镜像
> 使用kubeadm部署k8s集群01-初始化

##### 准备工具 cfssl, cfssljson, etcd, etcdctl（所有节点上需要）
curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /usr/local/bin/cfssl*

##### 下载 etcd 和 etcdctl
export ETCD_VERSION=v3.1.10
curl -sSL https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz | tar -xzv --strip-components=1 -C /usr/local/bin/
rm -rf etcd-$ETCD_VERSION-linux-amd64*

##### 同步到另外2个节点
rsync -avzP /usr/local/bin/* 10.222.0.101:/usr/local/bin/
rsync -avzP /usr/local/bin/* 10.222.0.102:/usr/local/bin/

```


##### 创建 etcd CA 证书
```bash
##### 在 master-100 上操作
mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd/

cat >ca-config.json <<_EOF
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
_EOF

cat >ca-csr.json <<_EOF
{
    "CN": "etcd",
    "key": {
        "algo": "rsa",
        "size": 2048
    }
}
_EOF

##### 生成 CA 证书
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

##### 输出
ca.pem
ca-key.pem

```


##### 创建 etcd client 证书
```bash
cat >client.json <<_EOF
{
    "CN": "client",
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
_EOF

##### 生成 client 证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client

##### 输出
client.pem
client-key.pem

```

##### 同步 ca 和 client 的证书相关文件到另外 2 个节点
```bash
rsync -avzP /etc/kubernetes/pki 10.222.0.101:/etc/kubernetes/
rsync -avzP /etc/kubernetes/pki 10.222.0.102:/etc/kubernetes/

```

##### 创建 server 和 peer 证书（所有节点上操作）
```bash
##### 设置环境变量
export PEER_NAME=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+' |awk -F'.' '{print "master-"$4}')
export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')


cfssl print-defaults csr > config.json
sed -i '0,/CN/{s/example\.net/'"$PEER_NAME"'/}' config.json
sed -i 's/www\.example\.net/'"$PRIVATE_IP"'/' config.json
sed -i 's/example\.net/'"$PEER_NAME"'/' config.json

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server config.json | cfssljson -bare server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer config.json | cfssljson -bare peer

```

#### 创建 etcd 服务对应到 systemd 配置（所有节点上操作）
```bash


##### 准备 etcd 服务依赖的环境变量
echo "PEER_NAME=$PEER_NAME" > /etc/etcd.env
echo "PRIVATE_IP=$PRIVATE_IP" >> /etc/etcd.env

##### 准备 etcd 服务的配置文件
cat >/etc/systemd/system/etcd.service <<_EOF
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
    --initial-cluster master-100=https://10.222.0.100:2380,master-101=https://10.222.0.101:2380,master-102=https://10.222.0.102:2380 \
    --initial-cluster-token my-etcd-token \
    --initial-cluster-state new

[Install]
WantedBy=multi-user.target

_EOF

##### 激活 etcd 服务
systemctl daemon-reload
systemctl enable etcd

##### 启动
systemctl start etcd
systemctl status etcd

##### 测试
export ETCDCTL_DIAL_TIMEOUT=3s
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.pem
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/client.pem
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/client-key.pem
export ETCDCTL_API=3
export ENDPOINTS="https://10.222.0.100:2379,https://10.222.0.101:2379,https://10.222.0.102:2379"

etcdctl --endpoints=${ENDPOINTS} -w table endpoint status
etcdctl --endpoints=${ENDPOINTS} put foo bar
etcdctl --endpoints=${ENDPOINTS} get --prefix ''

```

### 配置 k8s master

##### 初始化 master-100
```bash
mkdir -p ~/k8s_install/master/init
cd ~/k8s_install/master/init

##### 备份 etcd 证书（该 etcd 集群的所有节点都要备份自己的证书）
cp -a /etc/kubernetes/pki/etcd ~/k8s_install/master/init/
##### 后续如果 kubeadm reset 将导致 pki 目录被清空，此时可以恢复证书
cp -a ~/k8s_install/master/init/etcd /etc/kubernetes/pki/

##### 准备配置用于初始化
export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')

cat >config.yaml <<_EOF
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
_EOF

##### 开始初始化 master
kubeadm init --config=config.yaml

##### 使用 kubectl
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

##### 查看状态
kubectl get ds,deploy,svc,pods --all-namespaces
kubectl get nodes

```


##### 初始化 网络插件之 calico
```bash
##### 关于 calico 的更多内容，请参考笔记：使用kubeadm部署k8s集群01-初始化
[root@master-100 ~]# mkdir -p ~/k8s_install/network/calico
[root@master-100 ~]# cd ~/k8s_install/network/calico
[root@master-100 calico]# curl -so calico-v3.0.yaml https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml

##### 所有节点提前准备好镜像，类似下述实例中，缓存 `calico-v3.0.yaml` 使用的镜像，并打包同步到集群所有节点上
[root@master-100 calico]# grep 'image' calico-v3.0.yaml |uniq |sed -e 's#^.*image: quay.io#docker pull quay.io#g'
docker pull quay.io/coreos/etcd:v3.1.10
docker pull quay.io/calico/node:v3.0.4
docker pull quay.io/calico/cni:v2.0.3
docker pull quay.io/calico/kube-controllers:v2.0.2

[root@master-100 calico]# docker save -o calico-v3.0.tar quay.io/coreos/etcd:v3.1.10 quay.io/calico/node:v3.0.4 quay.io/calico/cni:v2.0.3 quay.io/calico/kube-controllers:v2.0.2
[root@master-100 calico]# scp calico-v3.0.tar 10.222.0.100:~/k8s_install/network/calico/
[root@master-102 calico]# docker load -i ~/k8s_install/network/calico/calico-v3.0.tar


##### 注意 CALICO_IPV4POOL_CIDR 是否和 podSubnet 一致，默认的需要替换：
[root@master-100 calico]# sed -i 's#192.168.0.0/16#172.30.0.0/16#' calico-v3.0.yaml

##### 启用
[root@master-100 calico]# kubectl apply -f calico-v3.0.yaml

##### 验证网络正常的方法是：检查 deploy/kube-dns 是否上线
```


> [警告]
```
来自今天（2018-04-24）的实验结果：
从下一步开始，加入多个 master 节点后，通过验证 `calico` 和 `kube-dns` 并不能表明网络可用。

实际上，需要验证业务，因为我在实验过程中发现一个问题：

业务 t1 部署后，运行在节点 worker-201 上，此时能通过 worker-201 的 ip:port 访问，但无法通过集群的其他节点来访问

小结： 新的 master 节点在加入过程中，对 iptables 规则的变化产生了影响。可能原因是：新的服务上线后，更新了节点 worker-201 上的 iptables 规则，但遇到权限异常，无法写入 calico-etcd 集群中，从而更新其他节点上的 iptables 规则

诉求： 请大家仔细验证业务，确认网络是否有异常！！后续将抽空研究该问题。
````

##### 初始化 master-101 master-102
> 将 master-101 加入集群（ 因 master-102 的操作同理，略过）
>  同步在 master-100 上生成的 pki 相关的证书文件（除了 etcd 这个目录由于已经存在不会被 scp 同步），实际上，我们只需要重建 `apiserver.*` 相关的证书
```bash
scp 10.222.0.100:/etc/kubernetes/pki/* /etc/kubernetes/pki
rm apiserver.*
```
> 接下来，重复前述操作中，初始化 master-100 的指令即可将该节点加入集群。

> 提示：只是同步 `ca.*` 和 `sa.*` 证书（照着 `Option 2: Copy paste` 描述的操作）可能是错误的，至少在我的实验环境中，遇到了异常，导致 kube-dns 无法上线，如果你也遇到类似的场景，请仔细查看 apiserver 的 pod 的日志输出是否有异常。



##### 如果需要重置 kubeadm 初始化的节点(例如，重做一次)

```bash
##### 这里以清理 master-102 这个节点为例说明：
##### 先在 master-100 上操作
kubectl drain master-102 --delete-local-data --force --ignore-daemonsets
kubectl delete node master-102

##### 然后在 master-102 上操作
kubeadm reset

##### 还原 etcd 相关的证书（因为 master-102 刚好也是 etcd 集群的节点）
cp -a ~/k8s_install/master/init/etcd /etc/kubernetes/pki/


```


### 配置 k8s worker
```bash
##### 加入集群
kubeadm join --token xxx.xxxxxxx 10.222.0.100:6443 --discovery-token-ca-cert-hash sha256:xxx

```


> [警告]
```
（注明：未完成，下述内容待验证）
```

### 配置 worker 使用 kube-proxy 时通过 LB 来访问后端高可用的 apiserver 服务
```bash
kubectl get configmap -n kube-system kube-proxy -o yaml > kube-proxy-cm.yaml
sed -i 's#server:.*#server: https://10.222.0.88:6443#g' kube-proxy-cm.yaml
kubectl apply -f kube-proxy-cm.yaml --force
kubectl delete pod -n kube-system -l k8s-app=kube-proxy


##### 更新 worker 上 kubelet 服务
sed -i 's#server:.*#server: https://10.222.0.88:6443#g' /etc/kubernetes/kubelet.conf
systemctl restart kubelet
```

上述 kube-proxy 是一个 daemonset 类型的服务，也就是说 master 节点上也会有该服务，此时思考下述数据流向是否会有异常：
```
kube-proxy(on master-100) -> LB(backend to master-100)
```

上述场景，如果是 LVS/DR 模式的 LB 则意味着
```
RS1 -> LB1 -> RS1
导致：
RS1 -> RS1
```

引用来自阿里云 SLB 的文档片段（实际遇到的一个坑）
> 5. 后端ECS实例为什么访问不了负载均衡服务？
> 这和负载均衡TCP的实现机制有关。在四层TCP协议服务中，不支持后端ECS实例既作为Real Server又作为客户端向所在的负载均衡实例发送请求。因为返回的数据包只在云服务器内部转发，不经过负载均衡，所以在后端ECS实例上去访问负载均衡的服务地址是不通的。

结论1：如果从 master 节点的 IP 来访问 k8s 中的访问，可能出现异常。
结论2：仅将 worker 节点的 IP 添加到 SLB 中作为后端，预计能避免上述异常。




### ZYXW、参考
1. [Creating HA clusters with kubeadm](https://kubernetes.io/docs/setup/independent/high-availability/)
2. [阿里云-SLB-后端服务器常见问题-后端ECS实例为什么访问不了负载均衡服务？](https://help.aliyun.com/knowledge_detail/55198.html)
3. [Two bug fixes to HA guide for kubeadm: #7451](https://github.com/kubernetes/website/pull/7451)
