# 使用kubeadm部署k8s集群07-扩容kube-scheduler到3节点
2018/1/4


### 扩容 kube-scheduler 到 3 节点
  - 连接到本节点的 apiserver
```bash
[root@tvm-00 kube-controller-manager]# cat /etc/kubernetes/manifests/kube-scheduler.yaml |grep '/etc/kubernetes'
  - --kubeconfig=/etc/kubernetes/scheduler.conf
  - mountPath: /etc/kubernetes/scheduler.conf
    path: /etc/kubernetes/scheduler.conf

显然，我们需要 2 个配置文件：
/etc/kubernetes/scheduler.conf
/etc/kubernetes/manifests/kube-scheduler.yaml

查看文件内容发现，只有一个配置需要更改 IP 地址指向对应的 apiserver 地址：
/etc/kubernetes/scheduler.conf

[root@tvm-00 ~]# mkdir ~/k8s_install/master/kube-scheduler
[root@tvm-00 ~]# cd !$

### 修改配置：
[root@tvm-00 kube-scheduler]# cp -a /etc/kubernetes/scheduler.conf tvm-01.scheduler.conf
[root@tvm-00 kube-scheduler]# sed -i 's#10.10.9.67:6443#10.10.9.68:6443#' tvm-01.scheduler.conf

### 同步配置到目标节点来启动服务：
[root@tvm-00 kube-scheduler]# scp tvm-01.scheduler.conf 10.10.9.68:/etc/kubernetes/scheduler.conf
[root@tvm-00 kube-scheduler]# scp /etc/kubernetes/manifests/kube-scheduler.yaml 10.10.9.68:/etc/kubernetes/manifests/

### 检查是否有异常：
[root@tvm-00 ~]# kubectl get pods --all-namespaces |grep 'kube-scheduler-tvm'
[root@tvm-00 ~]# kubectl logs --tail=20 -n kube-system kube-scheduler-tvm-01

### 在另一个节点操作：
### 修改配置：
[root@tvm-00 kube-scheduler]# cp -a /etc/kubernetes/scheduler.conf tvm-02.scheduler.conf
[root@tvm-00 kube-scheduler]# sed -i 's#10.10.9.67:6443#10.10.9.69:6443#' tvm-02.scheduler.conf

### 同步配置到目标节点来启动服务：
[root@tvm-00 kube-scheduler]# scp tvm-02.scheduler.conf 10.10.9.69:/etc/kubernetes/scheduler.conf
[root@tvm-00 kube-scheduler]# scp /etc/kubernetes/manifests/kube-scheduler.yaml 10.10.9.69:/etc/kubernetes/manifests/
```
