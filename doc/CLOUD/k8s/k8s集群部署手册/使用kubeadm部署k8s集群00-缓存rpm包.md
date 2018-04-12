# 使用kubeadm部署k8s集群00-缓存rpm包
2018/4/12

> 鉴于部分童鞋不知道如何缓存 rpm 包到本地
> 下述操作在国外节点上操作


使用官方 yum 源
```bash
# mkdir k8s_rpms && cd k8s_rpms
# cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

```


通过 yum 插件缓存 rpm 包到本地，而不是直接安装
```
# yum install yum-plugin-downloadonly -y
# yum install --downloadonly --downloaddir=./ kubelet kubeadm kubectl
已加载插件：fastestmirror
Loading mirror speeds from cached hostfile
 * base: repos-va.psychz.net
 * epel: mirror.solarvps.com
 * extras: mirror.trouble-free.net
 * updates: mirrors.gigenet.com
正在解决依赖关系
--> 正在检查事务
---> 软件包 kubeadm.x86_64.0.1.9.0-0 将被 安装
--> 正在处理依赖关系 kubernetes-cni，它被软件包 kubeadm-1.9.0-0.x86_64 需要
---> 软件包 kubectl.x86_64.0.1.9.0-0 将被 安装
---> 软件包 kubelet.x86_64.0.1.9.0-0 将被 安装
--> 正在处理依赖关系 socat，它被软件包 kubelet-1.9.0-0.x86_64 需要
--> 正在检查事务
---> 软件包 kubernetes-cni.x86_64.0.0.6.0-0 将被 安装
---> 软件包 socat.x86_64.0.1.7.3.2-2.el7 将被 安装
--> 解决依赖关系完成

# ls
8f507de9e1cc26e5b0043e334e26d62001c171d8e54d839128e9bade25ecda95-kubelet-1.9.0-0.x86_64.rpm  fe33057ffe95bfae65e2f269e1b05e99308853176e24a4d027bc082b471a07c0-kubernetes-cni-0.6.0-0.x86_64.rpm
aa9948f82e7af317c97a242f3890985159c09c183b46ac8aab19d2ad307e6970-kubeadm-1.9.0-0.x86_64.rpm  socat-1.7.3.2-2.el7.x86_64.rpm
bc390a3d43256791bfb844696e7215fd7ad8a09f70a42667dab4997415a6ba75-kubectl-1.9.0-0.x86_64.rpm

# mv *kubelet* kubelet-1.9.0-0.x86_64.rpm
# mv *kubeadm* kubeadm-1.9.0-0.x86_64.rpm
# mv *kubectl* kubectl-1.9.0-0.x86_64.rpm
# mv *kubernetes-cni-* kubernetes-cni-0.6.0-0.x86_64.rpm
# ls
kubeadm-1.9.0-0.x86_64.rpm  kubectl-1.9.0-0.x86_64.rpm  kubelet-1.9.0-0.x86_64.rpm  kubernetes-cni-0.6.0-0.x86_64.rpm  README.md  socat-1.7.3.2-2.el7.x86_64.rpm

```


通过 http 的方式同步到国内节点后，通过下述方式来安装
```bash
# yum localinstall -y k8s_rpms/*.rpm

```
