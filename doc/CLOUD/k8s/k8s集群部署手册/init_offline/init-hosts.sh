#!/bin/bash
#
# 2018/2/23
set -e

tee /etc/hosts <<-'_EOF'
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6


### k8s master @envTest
10.222.0.100 master-100
10.222.0.101 master-101
10.222.0.102 master-102

### k8s worker @envTest
10.222.0.200 worker-200

_EOF


cat <<'_EOF' >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
_EOF

sysctl --system
