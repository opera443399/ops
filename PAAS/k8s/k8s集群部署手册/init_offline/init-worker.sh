#!/bin/bash
#
# 2018/4/4
set -e

print_info() {
  echo "[I] -----------------> $1"
}

### init docker
print_info 'init docker'

yum -y install yum-utils \
&& yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo \
&& yum makecache fast \
&& yum -y install docker-ce-17.09.1.ce-1.el7.centos.x86_64 \
&& mkdir -p /data/docker \
&& mkdir -p /etc/docker; tee /etc/docker/daemon.json <<-'EOF'
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
systemctl daemon-reload && systemctl enable docker && systemctl start docker


### init k8s
print_info 'init k8s v1.9.0'
yum localinstall -y k8s_rpms_1.9/*.rpm
sed -i 's#--cgroup-driver=systemd#--cgroup-driver=cgroupfs#' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl enable kubelet

print_info 'load images for k8s worker'
docker load -i gcr.io/gcr.io-worker.tar
