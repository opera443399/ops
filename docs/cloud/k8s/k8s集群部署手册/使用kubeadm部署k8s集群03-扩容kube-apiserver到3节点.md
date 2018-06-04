# 使用kubeadm部署k8s集群03-扩容kube-apiserver到3节点
2018/1/3


### 扩容 kube-apiserver 到 3 节点
  - 配置 kube-apiserver.yaml
  - 分析 kube-apiserver 依赖的证书
  - 为新节点生成专属证书
  - 下发证书到对应的节点
  - 确认每个节点的 apiserver 是否处于 Running 状态

##### 配置 kube-apiserver.yaml
```bash
### 拷贝原 master 上的配置：
[root@tvm-00 ~]# mkdir -p ~/k8s_install/master/manifests
[root@tvm-00 ~]# cd !$
[root@tvm-00 manifests]# cp -a /etc/kubernetes/manifests/kube-apiserver.yaml tvm-01.kube-apiserver.yaml
### 替换 ip 信息：
[root@tvm-00 manifests]# sed -i 's#10.10.9.67#10.10.9.68#' tvm-01.kube-apiserver.yaml

[root@tvm-00 manifests]# cp -a /etc/kubernetes/manifests/kube-apiserver.yaml tvm-02.kube-apiserver.yaml
### 替换 ip 信息：
[root@tvm-00 manifests]# sed -i 's#10.10.9.67#10.10.9.69#' tvm-02.kube-apiserver.yaml

### 启动：
[root@tvm-00 manifests ~]# scp tvm-01.kube-apiserver.yaml 10.10.9.68:/etc/kubernetes/manifests/kube-apiserver.yaml
[root@tvm-00 manifests ~]# scp tvm-02.kube-apiserver.yaml 10.10.9.69:/etc/kubernetes/manifests/kube-apiserver.yaml

### 但，查看 pods 的状态发现，需要证书
[root@tvm-00 ~]# kubectl get pods --all-namespaces |grep 'kube-apiserver-tvm'
kube-system   kube-apiserver-tvm-00            1/1       Running            0          2h
kube-system   kube-apiserver-tvm-01            0/1       CrashLoopBackOff   5          5m
kube-system   kube-apiserver-tvm-02            0/1       CrashLoopBackOff   5          3m
[root@tvm-00 ~]# kubectl logs -n kube-system --tail=20 kube-apiserver-tvm-01
I1226 10:35:46.521561       1 server.go:121] Version: v1.9.0
unable to load server certificate: open /etc/kubernetes/pki/apiserver.crt: no such file or directory
```

##### 分析 kube-apiserver 依赖的证书
```bash
### 查看下 kube-apiserver 依赖了哪些证书：
[root@tvm-00 pki]# cat /etc/kubernetes/manifests/kube-apiserver.yaml |grep '=/etc/kubernetes/pki' |sort
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
    - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
    - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key

### 其中，可以直接拿来复用的有以下几个：
ca.crt
apiserver-kubelet-client.crt
apiserver-kubelet-client.key
front-proxy-ca.crt
front-proxy-client.key
sa.pub

### 需要为每个 master 节点重新生成证书的有以下几个：
apiserver.crt
apiserver.key

### 基本思路确定了，开始干活
### 先查看当前 master 上的 apiserver.crt 证书里边有什么内容

[root@tvm-00 ~]# cd /etc/kubernetes/pki/
[root@tvm-00 pki]# openssl x509 -noout -text -in apiserver.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1949677591623098936 (0x1b0ea570933be238)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=kubernetes
        Validity
            Not Before: Dec 22 08:24:18 2017 GMT
            Not After : Dec 22 08:24:19 2018 GMT
        Subject: CN=kube-apiserver
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                ###（输出略）
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Alternative Name:
                DNS:tvm-00, DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, IP Address:10.96.0.1, IP Address:10.10.9.67
    Signature Algorithm: sha256WithRSAEncryption
    ###（输出略）
```

##### 为新节点生成专属证书
```bash
### 准备工作，先拷贝当前 master 上的 key 并移除 apiserver 证书，后续复用此处的证书：
[root@tvm-00 ~]# mkdir -p ~/k8s_install/master/pki/original
[root@tvm-00 ~]# cd !$
[root@tvm-00 original]# cp -a /etc/kubernetes/pki/* . && rm -f apiserver.key apiserver.crt

### 准备工作，复用证书，生成本节点专属的 apiserver 证书：
[root@tvm-00 ~]# mkdir -p ~/k8s_install/master/pki/tvm-01
[root@tvm-00 ~]# cd !$
[root@tvm-00 tvm-01]# cp -a ../original/* .
### 生成2048位的密钥对：
[root@tvm-00 tvm-01]# openssl genrsa -out apiserver.key 2048
Generating RSA private key, 2048 bit long modulus
.....+++
..........................................................+++
e is 65537 (0x10001)

### 生成证书签署请求文件：
[root@tvm-00 tvm-01]# openssl req -new -key apiserver.key -subj "/CN=kube-apiserver," -out apiserver.csr

### 生成 ext 文件：
[root@tvm-00 tvm-01]# echo 'subjectAltName = DNS:tvm-01,DNS:kubernetes,DNS:kubernetes.default,DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, IP:10.96.0.1, IP:10.10.9.68' >apiserver.ext


### 使用 ca.key 和 ca.crt 签署上述请求：
[root@tvm-00 tvm-01]# openssl x509 -req -in apiserver.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out apiserver.crt -days 365 -extfile apiserver.ext
Signature ok
subject=/CN=kube-apiserver,
Getting CA Private Key

### 查看新生成的证书：
[root@tvm-00 tvm-01]# openssl x509 -noout -text -in apiserver.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 12945856570840330031 (0xb3a8ebf60a182f2f)
    Signature Algorithm: sha1WithRSAEncryption
        Issuer: CN=kubernetes
        Validity
            Not Before: Dec 26 10:54:23 2017 GMT
            Not After : Dec 26 10:54:23 2018 GMT
        Subject: CN=kube-apiserver,
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                （输出略）
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Alternative Name:
                DNS:tvm-01, DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, IP Address:10.96.0.1, IP Address:10.10.9.68
    Signature Algorithm: sha1WithRSAEncryption
    （输出略）

### 另一个节点类似：
### 准备工作，复用证书，生成本节点专属的 apiserver 证书：
[root@tvm-00 ~]# mkdir -p ~/k8s_install/master/pki/tvm-02
[root@tvm-00 ~]# cd !$

[root@tvm-00 tvm-02]# cp -a ../original/* .
### 生成2048位的密钥对：
[root@tvm-00 tvm-02]# openssl genrsa -out apiserver.key 2048
### 生成证书签署请求文件：
[root@tvm-00 tvm-02]# openssl req -new -key apiserver.key -subj "/CN=kube-apiserver," -out apiserver.csr
### 生成 ext 文件：
[root@tvm-00 tvm-02]# echo 'subjectAltName = DNS:tvm-02,DNS:kubernetes,DNS:kubernetes.default,DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, IP:10.96.0.1, IP:10.10.9.69' >apiserver.ext

### 使用 ca.key 和 ca.crt 签署上述请求：
[root@tvm-00 tvm-02]# openssl x509 -req -in apiserver.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out apiserver.crt -days 365 -extfile apiserver.ext

### 查看新生成的证书：
[root@tvm-00 tvm-02]# openssl x509 -noout -text -in apiserver.crt
```

##### 下发证书到对应的节点
```bash
[root@tvm-00 ~]# cd ~/k8s_install/master/pki
[root@tvm-00 pki]# scp tvm-01/* 10.10.9.68:/etc/kubernetes/pki/
[root@tvm-00 pki]# scp tvm-02/* 10.10.9.69:/etc/kubernetes/pki/
```

##### 确认每个节点的 apiserver 是否处于 Running 状态
```bash
### 查看 pods 的状态
[root@tvm-00 ~]# kubectl get pods --all-namespaces |grep 'kube-apiserver-tvm'
kube-system   kube-apiserver-tvm-00            1/1       Running   0          17h
kube-system   kube-apiserver-tvm-01            1/1       Running   184        15h
kube-system   kube-apiserver-tvm-02            1/1       Running   183        15h

### 符合预期
```






### ZYXW、参考
1. [一步步打造基于Kubeadm的高可用Kubernetes集群-第二部分](http://tonybai.com/2017/05/15/setup-a-ha-kubernetes-cluster-based-on-kubeadm-part2/)
