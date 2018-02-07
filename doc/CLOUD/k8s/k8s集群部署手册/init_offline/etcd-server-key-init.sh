#!/bin/bash
#
# 2018/2/7
set -e

print_info() {
  echo "[I] -----------------> $1"
}

##### 准备工具 cfssl, cfssljson, etcd, etcdctl
print_info 'prepare cfssl, etcd'
curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /usr/local/bin/cfssl*

##### 下载 etcd 和 etcdctl
export ETCD_VERSION=v3.1.10
curl -sSL https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz | tar -xzv --strip-components=1 -C /usr/local/bin/
rm -rf etcd-$ETCD_VERSION-linux-amd64*

rsync -avzP /usr/local/bin/* 10.222.0.101:/usr/local/bin/
rsync -avzP /usr/local/bin/* 10.222.0.102:/usr/local/bin/


print_info 'ca.pem, ca-key.pem'
mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd/

##### 生成 CA 证书
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
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

##### 生成 client 证书
print_info 'client.pem, client-key.pem'
cat >client.json <<EOL
{
    "CN": "client",
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
EOL
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client

##### 同步 ca 和 client 的证书相关文件到另外 2 个节点
rsync -avzP /etc/kubernetes/pki 10.222.0.101:/etc/kubernetes/
rsync -avzP /etc/kubernetes/pki 10.222.0.102:/etc/kubernetes/
