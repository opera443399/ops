# k8s基本概念-如何使用私有regsitry
2018/1/9


### 私有 regsitry 使用示例
  - 准备资源
  - 通过 secret 来使用
  - 关联到 serviceAccounts


##### 准备资源
  - 一个私有 regsitry 地址、账号、密码


##### 通过 secret 来使用
```bash
### 命令行登录一次 regsitry 后，生成配置：~/.docker/config.json
[root@tvm-00 k8s]# docker login --username=xxx registry.cn-hangzhou.aliyuncs.com

### 准备一个 secret
[root@tvm-00 k8s]# cat secrets/hub-aliyun-demo-project-ns-dev.yaml
apiVersion: v1
kind: Secret
metadata:
  name: hub-aliyun-demo-project-ns-dev
  namespace: ns-dev
data:
  .dockerconfigjson: {base64 -w 0 ~/.docker/config.json}
type: kubernetes.io/dockerconfigjson

### 注意上述 {base64 -w 0 ~/.docker/config.json} 代表执行该指令后得到到结果：
[root@tvm-00 k8s]# base64 -w 0 ~/.docker/config.json


### 创建 secret
[root@tvm-00 k8s]# kubectl apply -f secrets/hub-aliyun-demo-project-ns-dev.yaml
[root@tvm-00 k8s]# kubectl -n ns-dev get secrets
NAME                               TYPE                                  DATA      AGE
default-token-xb8lp                kubernetes.io/service-account-token   3         4d
hub-aliyun-demo-project-ns-dev     kubernetes.io/dockerconfigjson        1         6m

```

##### 关联到 serviceAccounts
  - 这样一来，每个 pod 创建时，将自动加载该资源
```bash
[root@tvm-00 k8s]# kubectl -n ns-dev get serviceAccounts
NAME      SECRETS   AGE
default   1         4d
[root@tvm-00 ns-dev]# kubectl -n ns-dev describe serviceAccounts/default
Name:                default
Namespace:           ns-dev
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   default-token-xb8lp
Tokens:              default-token-xb8lp
Events:              <none>

### 关联
[root@tvm-00 ns-dev]# kubectl -n ns-dev patch serviceaccount default -p '{"imagePullSecrets": [{"name": "hub-aliyun-demo-project-ns-dev"}]}'
serviceaccount "default" patched
[root@tvm-00 ns-dev]# kubectl -n ns-dev describe serviceAccounts/default
Name:                default
Namespace:           ns-dev
Labels:              <none>
Annotations:         <none>
Image pull secrets:  hub-aliyun-demo-project-ns-dev
Mountable secrets:   default-token-xb8lp
Tokens:              default-token-xb8lp
Events:              <none>
```

##### 验证
```bash
### 准备一个服务
[root@tvm-00 ns-dev]# cat whoami/k8s.ns-dev.yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: s1
  labels:
    app.name: whoami
  namespace: ns-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app.name: whoami
  template:
    metadata:
      labels:
        app.name: whoami
    spec:
      containers:
      - name: whoami
        image: registry.cn-hangzhou.aliyuncs.com/ns-demo-project/whoami:0.9
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: s1
  labels:
    app.name: whoami
  namespace: ns-dev
spec:
  selector:
      app.name: whoami
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30011
  type: NodePort

[root@tvm-00 ns-dev]# kubectl apply -f ./whoami/k8s.ns-dev.yaml --record
deployment "s1" created
service "s1" created

### 服务跑起来后，看看状态是否符合预期
[root@tvm-00 ns-dev]# kubectl -n ns-dev get deploy/s1
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
s1        1         1         1            1           16s
[root@tvm-00 ns-dev]# kubectl -n ns-dev get pods -l app.name=whoami
NAME                  READY     STATUS    RESTARTS   AGE
s1-65b7fcbfd5-vn4n9   1/1       Running   0          1m

[root@tvm-00 ns-dev]# curl localhost:30011
Hostname: s1-65b7fcbfd5-vn4n9

---- Http Request Headers ----

GET / HTTP/1.1
Host: localhost:30011
User-Agent: curl/7.29.0
Accept: */*


---- Active Endpoint ----

[howto] version: 0.9
    curl 127.0.0.1/
    curl 127.0.0.1/?wait=2s
    curl 127.0.0.1/test
    curl 127.0.0.1/api
    curl 127.0.0.1/health
    curl 127.0.0.1/health -d '302'


### 看一下 pods 的状态中 Image 相关的信息
[root@tvm-00 ns-dev]# kubectl -n ns-dev describe pods -l app.name=whoami
Name:           s1-65b7fcbfd5-vn4n9
Namespace:      ns-dev
Node:           tvm-02/10.10.9.69
Start Time:     Tue, 02 Jan 2018 14:32:46 +0800
Labels:         app.name=whoami
                pod-template-hash=2163976981
Annotations:    <none>
Status:         Running
IP:             172.30.11.68
Controlled By:  ReplicaSet/s1-65b7fcbfd5
Containers:
  whoami:
    Container ID:   docker://c8e02546250e9e9083f659e315627a75235ae0098d6854293e26c97390ac82f2
    Image:          registry.cn-hangzhou.aliyuncs.com/ns-demo-project/whoami:0.9
    Image ID:       docker-pullable://opera443399/whoami@sha256:a05120d9fe157868f7f1c8b842cc860fb58665d74cadaf8eb7d6091af626cccd
    Port:           80/TCP
    State:          Running
      Started:      Tue, 02 Jan 2018 14:32:47 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-xb8lp (ro)
Conditions:
  Type           Status
  Initialized    True
  Ready          True
  PodScheduled   True
Volumes:
  default-token-xb8lp:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-xb8lp
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason                 Age   From                             Message
  ----    ------                 ----  ----                             -------
  Normal  Scheduled              1m    default-scheduler                Successfully assigned s1-65b7fcbfd5-vn4n9 to tvm-02
  Normal  SuccessfulMountVolume  1m    kubelet, tvm-02  MountVolume.SetUp succeeded for volume "default-token-xb8lp"
  Normal  Pulling                1m    kubelet, tvm-02  pulling image "registry.cn-hangzhou.aliyuncs.com/ns-demo-project/whoami:0.9"
  Normal  Pulled                 1m    kubelet, tvm-02  Successfully pulled image "registry.cn-hangzhou.aliyuncs.com/ns-demo-project/whoami:0.9"
  Normal  Created                1m    kubelet, tvm-02  Created container
  Normal  Started                1m    kubelet, tvm-02  Started container
```

### ZYXW、参考
1. [Bypassing kubectl create secrets](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)
2. [Add ImagePullSecrets to a service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#adding-imagepullsecrets-to-a-service-account)
