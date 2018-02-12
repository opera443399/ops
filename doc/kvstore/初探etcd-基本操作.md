初探etcd-基本操作
2018/2/12

### 初识
- 用途
etcd是用于共享配置和服务发现的分布式、一致性的KV存储系统。本文重点是记录最新版本（目前是v3）的 etcd 服务的基本操作，因而将不定时更新本文。

- 版本
v2：restapi，基于目录
v3：grpc，使用protobuf，兼容了v2的接口，但不能混用（例如，使用v2的接口来获取v3版本保存的数据），使用v3的接口，需申明 ETCDCTL_API=3

- 目标
本次示例 v3 版本的基本操作，作为初步了解

- 下载
来自：https://github.com/coreos/etcd/releases
```bash
wget https://github.com/coreos/etcd/releases/download/v3.2.9/etcd-v3.2.9-linux-amd64.tar.gz
tar zxvf etcd-v3.2.9-linux-amd64.tar.gz
cp etcd-v3.2.9-linux-amd64/etcd* /usr/local/bin/
```



### etcd 服务使用示例
```bash
##### 启动服务
nohup etcd --name etcd_test --data-dir /tmp/etcd_test \
  --listen-client-urls 'http://127.0.0.1:2379,http://127.0.0.1:4001' \
  --listen-peer-urls 'http://127.0.0.1:2380' \
  --advertise-client-urls 'http://127.0.0.1:2379,http://127.0.0.1:4001' \
  >/var/log/etcd_test.log 2>&1 &

##### put
ETCDCTL_API=3 /usr/local/bin/etcdctl put foo bar
ETCDCTL_API=3 /usr/local/bin/etcdctl put testjson {"PublishedPort":"11111","Labels":[{"com.test.env":"dev"}]}


ETCDCTL_API=3 /usr/local/bin/etcdctl put "/docker/node/n01" "192.168.100.111"
ETCDCTL_API=3 /usr/local/bin/etcdctl put "/docker/node/n02" "192.168.100.112"
ETCDCTL_API=3 /usr/local/bin/etcdctl put "/docker/node/n03" "192.168.100.113"
ETCDCTL_API=3 /usr/local/bin/etcdctl put "/docker/service/s01" "1005"
ETCDCTL_API=3 /usr/local/bin/etcdctl put "/docker/service/s02" "1007"



##### get
##### 精确匹配
~]# ETCDCTL_API=3 /usr/local/bin/etcdctl get foo
foo
bar


##### 改变输出格式为 json
~]# ETCDCTL_API=3 /usr/local/bin/etcdctl get -w json foo
{"header":{"cluster_id":14841639068965178418,"member_id":10276657743932975437,"revision":13,"raft_term":2},"kvs":[{"key":"Zm9v","create_revision":12,"mod_revision":12,"version":1,"value":"YmFy"}],"count":1}


##### 注意，在 v3 的版本中 key 和 value 是经过 base64 编码的
~]# echo -n 'foo' |base64
Zm9v
~]# echo -n 'bar' |base64
YmFy



##### 前缀匹配
~]# ETCDCTL_API=3 /usr/local/bin/etcdctl get --prefix /docker
/docker/node/n01
192.168.100.111
/docker/node/n02
192.168.100.112
/docker/node/n03
192.168.100.113
/docker/service/s01
1005
/docker/service/s02
1007

~]# ETCDCTL_API=3 /usr/local/bin/etcdctl get --prefix /docker/node
/docker/node/n01
192.168.100.111
/docker/node/n02
192.168.100.112
/docker/node/n03
192.168.100.113

~]# ETCDCTL_API=3 /usr/local/bin/etcdctl get --prefix /docker/service
/docker/service/s01
1005
/docker/service/s02
1007


##### 获取所有的key
~]# ETCDCTL_API=3 /usr/local/bin/etcdctl get --prefix ""
/docker/node/n01
192.168.100.111
/docker/node/n02
192.168.100.112
/docker/node/n03
192.168.100.113
/docker/service/s01
1005
/docker/service/s02
1007
foo
bar
testjson
PublishedPort:11111

```


### 附加：使用 confd 读取 etcd 中的数据
```bash
##### 安装 confd
git clone https://github.com/kelseyhightower/confd.git $GOPATH/src/github.com/kelseyhightower/confd
cd $GOPATH/src/github.com/kelseyhightower/confd
make
cp bin/confd /usr/local/bin/
mkdir -p /etc/confd/{conf.d,templates}


##### 配置文件
~]# tree /etc/confd
/etc/confd
├── conf.d
│   └── nginx.toml
└── templates
    └── nginx.tmpl

2 directories, 2 files
~]# cat /etc/confd/conf.d/nginx.toml
[template]
prefix = "/docker"
src = "nginx.tmpl"
dest = "/tmp/myapp.conf"
owner = "nginx"
mode = "0644"
keys = [
  "/node",
  "/service",
]


~]# cat /etc/confd/templates/nginx.tmpl
{{range gets "/service/*"}}
upstream backend_{{base .Key}} { {{$port := .Value}} {{range getvs "/node/*"}}
    server {{.}}:{{$port}}{{end}}
}

server {
    server_name {{base .Key}}.example.com;
    location / {
        proxy_pass http://backend_{{base .Key}};
        proxy_redirect    off;
        proxy_set_header  Host             $host;
        proxy_set_header  X-Real-IP        $remote_addr;
        proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
    }
}
{{end}}



##### 测试
~]# confd -onetime -backend etcdv3 -node http://127.0.0.1:2379 >/dev/null 2>&1 && cat /tmp/myapp.conf

upstream backend_s01 {
    server 192.168.100.111:1005
    server 192.168.100.112:1005
    server 192.168.100.113:1005
}

server {
    server_name s01.example.com;
    location / {
        proxy_pass http://backend_s01;
        proxy_redirect    off;
        proxy_set_header  Host             $host;
        proxy_set_header  X-Real-IP        $remote_addr;
        proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
    }
}

upstream backend_s02 {
    server 192.168.100.111:1007
    server 192.168.100.112:1007
    server 192.168.100.113:1007
}

server {
    server_name s02.example.com;
    location / {
        proxy_pass http://backend_s02;
        proxy_redirect    off;
        proxy_set_header  Host             $host;
        proxy_set_header  X-Real-IP        $remote_addr;
        proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
    }
}

```



三、创建 etcd 集群
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
    --initial-cluster master-100=https://10.222.0.100:2380,master-101=https://10.222.0.101:2380,master-102=https://10.222.0.102:2380 \
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

##### 测试
ETCDCTL_API=3 etcdctl \
--endpoints="https://10.222.0.100:2379,https://10.222.0.101:2379,https://10.222.0.102:2379" \
--cacert=/etc/kubernetes/pki/etcd/ca.pem \
--cert=/etc/kubernetes/pki/etcd/client.pem \
--key=/etc/kubernetes/pki/etcd/client-key.pem \
-w table \
endpoint status

##### 如果要执行多个指令，可通过环境变量来简化：
export ETCDCTL_DIAL_TIMEOUT=3s
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.pem
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/client.pem
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/client-key.pem
export ETCDCTL_API=3
export ENDPOINTS="https://10.222.0.100:2379,https://10.222.0.101:2379,https://10.222.0.102:2379"

etcdctl --endpoints=${ENDPOINTS} -w table endpoint status


```





ZYXW、参考
1、官网doc
clustering: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/clustering.md
demo: https://github.com/coreos/etcd/blob/master/Documentation/demo.md
interacting: https://github.com/coreos/etcd/blob/master/Documentation/dev-guide/interacting_v3.md
api: https://coreos.com/etcd/docs/latest/v2/api.html

2、ETCD系列之一：简介
https://yq.aliyun.com/articles/11035
