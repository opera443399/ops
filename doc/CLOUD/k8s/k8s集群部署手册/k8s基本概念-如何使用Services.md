# k8s基本概念-如何使用Services
2017/12/28


### Services 使用示例
  - Virtual IPs and service proxies
  - Publishing services - service types
  - 通过命令行来控制 Service
  - 通过 yaml 配置文件来定义 Service



##### Virtual IPs and service proxies
  - Proxy-mode: userspace
    - 轮询
  - Proxy-mode: iptables
    - v1.2开始作为默认选项
    - 比 userspace 快
    - 注意：如果一开始选择的 pod 失去响应后，不能自动重试其他 pod 因而需要定义 readiness probes
    - 随机
  - Proxy-mode: ipvs
    - FEATURE STATE: Kubernetes v1.9 beta
    - 比 iptables 快

##### Publishing services - service types
  - ClusterIP
    - 创建一个 ClusterIP 来提供集群内部访问
    - 默认选项
  - NodePort
    - 在每个节点 IP 上暴露一个端口（NodePort）来提供服务，集群外部通过这种方式来访问：<NodeIP>:<NodePort>，同时会创建一个 ClusterIP
    - 这种类型使用较多
    - 默认暴露的随机端口范围：30000-32767
    - 可以通过 nodePort 字段来显式的指定端口
  - LoadBalancer
    - 通过和 cloud provider’s load balancer 关联使用，此时 NodePort and ClusterIP 将自动创建
  - ExternalName
    - 将 service 名称映射到一个 externalName （例如一个域名），通过 kube-dns 来提供 DNS 到 CNAME 记录


##### 通过命令行来控制 Service
- 获取和创建 service
```bash
### 获取所有的 service 列表：
[root@tvm-00 ~]# kubectl get services
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5d

### 创建一个网络类型为 NodePort 的 service 并暴露 pods 的 80 端口
[root@tvm-00 ~]# kubectl expose deployments/test-deployment-app-whoami --type="NodePort" --port 80
service "test-deployment-app-whoami" exposed

### 再次获取所有的 service 列表：
[root@tvm-00 ~]# kubectl get services
NAME                         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kubernetes                   ClusterIP   10.96.0.1      <none>        443/TCP        5d
test-deployment-app-whoami   NodePort    10.108.8.154   <none>        80:31816/TCP   9s

### 当然，也可以通过 label 来筛选：
[root@tvm-00 ~]# kubectl get services -l app=whoami
NAME                         TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
test-deployment-app-whoami   NodePort   10.108.8.154   <none>        80:31816/TCP   23s
```

- 查看细节
```bash
### 查看 service 的细节：
[root@tvm-00 ~]# kubectl describe services/test-deployment-app-whoami
Name:                     test-deployment-app-whoami
Namespace:                default
Labels:                   app=whoami
Annotations:              <none>
Selector:                 app=whoami
Type:                     NodePort
IP:                       10.108.8.154
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31816/TCP
Endpoints:                172.30.11.74:80,172.30.11.75:80,172.30.11.77:80 + 2 more...
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

### 此处也可以通过 label 来筛选
[root@tvm-00 ~]# kubectl describe services -l app=whoami
Name:                     test-deployment-app-whoami
Namespace:                default
Labels:                   app=whoami
Annotations:              <none>
Selector:                 app=whoami
Type:                     NodePort
IP:                       10.108.8.154
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31816/TCP
Endpoints:                172.30.11.74:80,172.30.11.75:80,172.30.11.77:80 + 2 more...
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

- 请求 service
```bash
[root@tvm-00 ~]# export NODE_PORT=$(kubectl get services/test-deployment-app-whoami -o go-template='{{(index .spec.ports 0).nodePort}}')
[root@tvm-00 ~]# echo NODE_PORT=$NODE_PORT
NODE_PORT=31816

[root@tvm-00 ~]# kubectl get pods -l app=whoami
NAME                                          READY     STATUS    RESTARTS   AGE
test-deployment-app-whoami-6cf9cd6bf4-2dd5m   1/1       Running   0          15h
test-deployment-app-whoami-6cf9cd6bf4-bb7v7   1/1       Running   0          15h
test-deployment-app-whoami-6cf9cd6bf4-c7cht   1/1       Running   0          15h
test-deployment-app-whoami-6cf9cd6bf4-jhtqz   1/1       Running   0          15h
test-deployment-app-whoami-6cf9cd6bf4-px24h   1/1       Running   0          15h

### 测试请求 10 次的结果：
[root@tvm-00 ~]# for i in $(seq 1 10); do curl -s tvm-00:$NODE_PORT|grep Hostname; done
Hostname: test-deployment-app-whoami-6cf9cd6bf4-jhtqz
Hostname: test-deployment-app-whoami-6cf9cd6bf4-bb7v7
Hostname: test-deployment-app-whoami-6cf9cd6bf4-px24h
Hostname: test-deployment-app-whoami-6cf9cd6bf4-jhtqz
Hostname: test-deployment-app-whoami-6cf9cd6bf4-2dd5m
Hostname: test-deployment-app-whoami-6cf9cd6bf4-c7cht
Hostname: test-deployment-app-whoami-6cf9cd6bf4-c7cht
Hostname: test-deployment-app-whoami-6cf9cd6bf4-bb7v7
Hostname: test-deployment-app-whoami-6cf9cd6bf4-jhtqz
Hostname: test-deployment-app-whoami-6cf9cd6bf4-px24h

### 符合预期，请求随机分布在 5 个 pods 上
```

- 删除 service
```bash
[root@tvm-00 ~]# kubectl delete services -l app=whoami
service "test-deployment-app-whoami" deleted
[root@tvm-00 ~]# kubectl get services
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5d
```


##### 通过 yaml 配置文件来定义 Service
- 创建配置文件
```bash
[root@tvm-00 ~]# cat ~/k8s_install/test/whoami/app.yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: app-whoami
  labels:
    app: whoami
spec:
  replicas: 3
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
      - name: whoami
        image: opera443399/whoami:0.9
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: svc-whoami
  labels:
    app: whoami
spec:
  selector:
    app: whoami
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort

```

- 执行
```bash
[root@tvm-00 ~]# kubectl apply -f whoami/app.yaml --record
deployment "app-whoami" created
service "svc-whoami" created
```

- 获取信息
```bash
[root@tvm-00 ~]# kubectl get all -l app=whoami
NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/app-whoami   3         3         3            3           25s

NAME                       DESIRED   CURRENT   READY     AGE
rs/app-whoami-6cf9cd6bf4   3         3         3         25s

NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/app-whoami   3         3         3            3           25s

NAME                       DESIRED   CURRENT   READY     AGE
rs/app-whoami-6cf9cd6bf4   3         3         3         25s

NAME                             READY     STATUS    RESTARTS   AGE
po/app-whoami-6cf9cd6bf4-2pxlh   1/1       Running   0          25s
po/app-whoami-6cf9cd6bf4-82ng2   1/1       Running   0          25s
po/app-whoami-6cf9cd6bf4-msbmk   1/1       Running   0          25s

NAME             TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
svc/svc-whoami   NodePort   10.96.100.22   <none>        80:30080/TCP   25s
```

- 测试
```bash
[root@tvm-00 ~]# curl -s 10.96.100.22:80 |grep Hostname
Hostname: app-whoami-6cf9cd6bf4-msbmk
[root@tvm-00 ~]# curl -s tvm-00:30080 |grep Hostname
Hostname: app-whoami-6cf9cd6bf4-2pxlh
[root@tvm-00 ~]# curl -s tvm-01:30080 |grep Hostname
Hostname: app-whoami-6cf9cd6bf4-2pxlh
[root@tvm-00 ~]# curl -s tvm-02:30080 |grep Hostname
Hostname: app-whoami-6cf9cd6bf4-msbmk
```
