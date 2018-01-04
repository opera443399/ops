# 使用kubeadm部署k8s集群06-扩容kube-controller-manager到3节点
2018/1/3


### 扩容 kube-controller-manager 到 3 节点
  - 连接到本节点的 apiserver
```bash
[root@tvm-00 ~]# cat /etc/kubernetes/manifests/kube-controller-manager.yaml |grep '/etc/kubernetes'
  - --kubeconfig=/etc/kubernetes/controller-manager.conf
  - --root-ca-file=/etc/kubernetes/pki/ca.crt
  - --service-account-private-key-file=/etc/kubernetes/pki/sa.key
  - --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt
  - --cluster-signing-key-file=/etc/kubernetes/pki/ca.key
  - mountPath: /etc/kubernetes/pki
  - mountPath: /etc/kubernetes/controller-manager.conf
    path: /etc/kubernetes/pki
    path: /etc/kubernetes/controller-manager.conf

### 显然，我们需要 2 个配置文件：
/etc/kubernetes/controller-manager.conf
/etc/kubernetes/manifests/kube-controller-manager.yaml

### 查看文件内容发现，只有一个配置需要更改 IP 地址指向对应的 apiserver 地址：
/etc/kubernetes/controller-manager.conf

[root@tvm-00 ~]# mkdir ~/k8s_install/master/kube-controller-manager
[root@tvm-00 ~]# cd !$

### 修改配置：
[root@tvm-00 kube-controller-manager]# cp -a /etc/kubernetes/controller-manager.conf tvm-01.controller-manager.conf
[root@tvm-00 kube-controller-manager]# sed -i 's#10.10.9.67:6443#10.10.9.68:6443#' tvm-01.controller-manager.conf

### 同步配置到目标节点来启动服务：
[root@tvm-00 kube-controller-manager]# scp tvm-01.controller-manager.conf 10.10.9.68:/etc/kubernetes/controller-manager.conf
[root@tvm-00 kube-controller-manager]# scp /etc/kubernetes/manifests/kube-controller-manager.yaml 10.10.9.68:/etc/kubernetes/manifests/

### 检查是否有异常：
[root@tvm-00 ~]# kubectl get pods --all-namespaces |grep 'kube-controller-manager-tvm'
[root@tvm-00 ~]# kubectl logs --tail=20 -n kube-system kube-controller-manager-tvm-01

### 在另一个节点操作：
### 修改配置：
[root@tvm-00 kube-controller-manager]# cp -a /etc/kubernetes/controller-manager.conf tvm-02.controller-manager.conf
[root@tvm-00 kube-controller-manager]# sed -i 's#10.10.9.67:6443#10.10.9.69:6443#' tvm-02.controller-manager.conf

### 同步配置到目标节点来启动服务：
[root@tvm-00 kube-controller-manager]# scp tvm-02.controller-manager.conf 10.10.9.69:/etc/kubernetes/controller-manager.conf
[root@tvm-00 kube-controller-manager]# scp /etc/kubernetes/manifests/kube-controller-manager.yaml 10.10.9.69:/etc/kubernetes/manifests/
```
