#!/bin/bash
#
# 2018/4/4
set -e

print_info() {
  echo "[I] -----------------> $1"
}

##### 设置环境变量
export PEER_NAME=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+' |awk -F'.' '{print "master-"$4}')
export PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')
print_info "export: PEER_NAME=$PEER_NAME, PRIVATE_IP=$PRIVATE_IP"

print_info 'server.pem, server-key.pem'
print_info 'peer.pem, peer-key.pem'
cd /etc/kubernetes/pki/etcd/
cfssl print-defaults csr > config.json
sed -i '0,/CN/{s/example\.net/'"$PEER_NAME"'/}' config.json
sed -i 's/www\.example\.net/'"$PRIVATE_IP"'/' config.json
sed -i 's/example\.net/'"$PEER_NAME"'/' config.json

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server config.json | cfssljson -bare server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer config.json | cfssljson -bare peer


##### 准备 etcd 服务依赖的环境变量
print_info 'setup systemd etcd.service'
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
