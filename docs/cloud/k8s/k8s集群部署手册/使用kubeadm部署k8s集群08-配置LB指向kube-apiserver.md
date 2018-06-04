# 使用kubeadm部署k8s集群08-配置LB指向kube-apiserver
2018/1/4


### 配置 LB 指向 kube-apiserver
  - 小目标：在 3 个 master 节点前，还需配置一个 LB 来作为 apiserver 的入口
    - LB -> master x3
  - 直接使用阿里云内网 SLB L4 proxy 资源（本次实例是 4 层而不使用 7 层的原因是：跳过了处理证书的环节）
    - 申请下来资源后，将得到一个 vip 指向上述 3 个 master 节点的 IP 作为后端真实服务器
    - 注意：做网络联通性测试时，不要在上述 3 个 master 节点上测试 vip 是否可用，因为这和负载均衡TCP的实现机制有关
  - 利用 haproxy/nginx 来自建 LB（测试通过，但建议使用阿里云到基础组件，不要自己维护）

##### 直接使用阿里云内网 SLB L4 proxy 资源
```bash
### 申请的 SLB 资源
SLB instance id: lb-xxx, vip: 10.10.9.76

### 网络联通性测试
[root@tvm-04 ~]# for i in $(seq 1 10);do echo "------------$i";curl -k -If -m 3 https://10.10.9.76:6443;done
------------1
curl: (22) NSS: client certificate not found (nickname not specified)

### 符合预期。出现上述的异常，表示是证书相关的问题，可以通过域名解析到这个 vip 来绕过
### 选一个域名（之前在为每个节点创建证书时，使用的附加信息中有几个 DNS 可选）
### 例如：kubernetes.default.svc.cluster.local
### 后续集群外需要访问 apiserver 则请求到上述域名中，以此来规避 SLB 的 L4 proxy 没有证书的问题
###（上述域名写入目标测试节点的 hosts 中）
[root@tvm-04 ~]# vim /etc/hosts
（略）
### k8s apiserver SLB
10.10.9.76 kubernetes.default.svc.cluster.local


后续在配置 worker 节点时将会用到这里的域名
```

##### 利用 haproxy/nginx 来自建 LB
```bash
### 此处我们先配置一个单节点的 nginx L4 proxy 来测试（如果使用 L7 需要增加对应的证书）
[root@tvm-04 ~]# vim /etc/hosts
（略）
### k8s apiserver SLB
10.10.9.74 kubernetes.default.svc.cluster.local

### 在这台机器上配置 nginx L4 stream
[root@tvm-03 ~]# yum -y install nginx
[root@tvm-03 ~]# nginx -v
nginx version: nginx/1.12.2
[root@tvm-03 ~]# mkdir -p /etc/nginx/stream.conf.d
[root@tvm-03 ~]# cat <<'_EOF' >>/etc/nginx/nginx.conf
stream {
    log_format proxy '$remote_addr [$time_local] '
                     '$protocol $status $bytes_sent $bytes_received '
                     '$session_time "$upstream_addr" '
                     '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';
    access_log /var/log/nginx/stream.access.log proxy;
    include /etc/nginx/stream.conf.d/*.conf;
}
_EOF

[root@tvm-03 ~]# cat /etc/nginx/stream.conf.d/slb.test.apiserver.local.conf
#tcp: kubernetes.default.svc.cluster.local
upstream slb_test_apiserver_local {
    server 10.10.9.67:6443 weight=5 max_fails=3 fail_timeout=30s;
    server 10.10.9.68:6443 weight=5 max_fails=3 fail_timeout=30s;
    server 10.10.9.69:6443 weight=5 max_fails=3 fail_timeout=30s;
}

server {
    listen 7443;
    proxy_pass slb_test_apiserver_local;
    proxy_connect_timeout 1s;
    proxy_timeout 3s;
    access_log /var/log/nginx/slb_test_apiserver_local.log proxy;
}


### 启动 proxy
[root@tvm-03 ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
[root@tvm-03 ~]# systemctl start nginx.service
[root@tvm-03 ~]# systemctl enable nginx.service

###切换 apiserver 准备测试
[root@tvm-02 ~]# sed -i 's#10.10.9.69:6443#kubernetes.default.svc.cluster.local:7443#' ~/.kube/config
[root@tvm-02 ~]# kubectl get nodes
[root@tvm-02 ~]# kubectl get nodes
[root@tvm-02 ~]# grep kube /etc/hosts
10.10.9.74 kubernetes.default.svc.cluster.local
[root@tvm-02 ~]# kubectl cluster-info
Kubernetes master is running at https://kubernetes.default.svc.cluster.local:7443
KubeDNS is running at https://kubernetes.default.svc.cluster.local:7443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

### 查看 proxy 上的日志
[root@tvm-03 ~]# tail /var/log/nginx/slb_test_apiserver_local.log
10.10.9.69 [03/Jan/2018:12:34:13 +0800] TCP 200 26209 1947 0.217 "10.10.9.68:6443" "1947" "26209" "0.000"
10.10.9.69 [03/Jan/2018:12:34:15 +0800] TCP 200 26209 1947 0.284 "10.10.9.69:6443" "1947" "26209" "0.000"

###符合预期，下一步可以配置这个 LB 的高可用，扩容到 2 节点，通过 keepalived 之类到服务来提供 vip 服务即可。

```


### ZYXW、参考
1. [阿里云-SLB-后端服务器常见问题-后端ECS实例为什么访问不了负载均衡服务？](https://help.aliyun.com/knowledge_detail/55198.html)
