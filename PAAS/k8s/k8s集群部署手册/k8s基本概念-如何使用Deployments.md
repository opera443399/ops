# k8s基本概念-如何使用Deployments
2018/1/5


### Deployments 使用示例
  - 创建一个 app
  - 查看 app 状态
  - 更新 app
  - 回滚 app
  - 扩缩容 app
  - 删除 app


##### 创建一个 app
- 通过 yaml 配置文件来定义 Deployment
  - 关于 apiVersion 的写法，请参考：
    - https://github.com/kubernetes/kubernetes/blob/630dbedef9de9ef678f16132796b103b8a03fcda/pkg/api/testing/defaulting_test.go
  - 关于 metadata 中的 name
    - 定义来 deployment 的名称
    - 同一个 namespace 下名称不能重复
  - 关于 metadata 中的 labels
    - k/v 键值对
    - key 的命名规则
      - 必须
      - 包含一个可选的 prefix 和 name 并小于 64 字符
      - name 以字母和数字 [a-z0-9A-Z] 开头和结尾，中间可以是 dashes (-)，underscores (_)，dots (.)，字母和数字
      - prefix 是可选的，类似这样："kubernetes.io/" 暂不讨论
    - Value 的命名规则
      - 可以为空，或小于 64 字符
      - 以字母和数字 [a-z0-9A-Z] 开头和结尾，中间可以是 dashes (-)，underscores (_)，dots (.)，字母和数字
  - 关于 metadata 中的 namespace
    - 默认使用 default
```bash
[root@tvm-00 ~]# cat ~/k8s_install/test/whoami/app.yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: test-deployment-app-whoami
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
```

- 运行 app
```bash
### 注意：使用 --record 可以记录指令的 history 便于后续 rolling update 选择
[root@tvm-00 ~]# kubectl apply -f ~/k8s_install/test/whoami/app.yaml --record
deployment "test-deployment-app-whoami" created
```

##### 查看 app 状态
- 查看信息
```bash
[root@tvm-00 ~]# kubectl get deployments
NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
test-deployment-app-whoami   3         3         3            3           5m
[root@tvm-00 ~]# kubectl get rs
NAME                                    DESIRED   CURRENT   READY     AGE
test-deployment-app-whoami-6cf9cd6bf4   3         3         3         5m
[root@tvm-00 ~]# kubectl get pods
NAME                                          READY     STATUS    RESTARTS   AGE
test-deployment-app-whoami-6cf9cd6bf4-59h9x   1/1       Running   0          5m
test-deployment-app-whoami-6cf9cd6bf4-978ht   1/1       Running   0          5m
test-deployment-app-whoami-6cf9cd6bf4-w5dhk   1/1       Running   0          5m
[root@tvm-00 ~]# kubectl get pods --show-labels
NAME                                          READY     STATUS    RESTARTS   AGE       LABELS
test-deployment-app-whoami-6cf9cd6bf4-59h9x   1/1       Running   0          7m        app=whoami,pod-template-hash=2795782690
test-deployment-app-whoami-6cf9cd6bf4-978ht   1/1       Running   0          7m        app=whoami,pod-template-hash=2795782690
test-deployment-app-whoami-6cf9cd6bf4-w5dhk   1/1       Running   0          7m        app=whoami,pod-template-hash=2795782690
```

##### 更新 app
- 试着更新 1 次镜像后，查看信息，重点留意版本历史
```bash
### 更新 image 为其他版本：
[root@tvm-00 ~]# kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.7
deployment "test-deployment-app-whoami" image updated

### 查看信息
[root@tvm-00 ~]# kubectl rollout status deployments/test-deployment-app-whoami
deployment "test-deployment-app-whoami" successfully rolled out
[root@tvm-00 ~]# kubectl get deployments
NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
test-deployment-app-whoami   3         3         3            3           11m
[root@tvm-00 ~]# kubectl get rs
NAME                                    DESIRED   CURRENT   READY     AGE
test-deployment-app-whoami-68c6cd964    3         3         3         42s
test-deployment-app-whoami-6cf9cd6bf4   0         0         0         11m
[root@tvm-00 ~]# kubectl get pods
NAME                                         READY     STATUS    RESTARTS   AGE
test-deployment-app-whoami-68c6cd964-bfznh   1/1       Running   0          54s
test-deployment-app-whoami-68c6cd964-r7vp5   1/1       Running   0          56s
test-deployment-app-whoami-68c6cd964-vssrj   1/1       Running   0          53s


[root@tvm-00 ~]# kubectl describe deployments/test-deployment-app-whoami
Name:                   test-deployment-app-whoami
Namespace:              default
CreationTimestamp:      Wed, 27 Dec 2017 17:44:30 +0800
Labels:                 app=whoami
Annotations:            deployment.kubernetes.io/revision=2
                        kubectl.kubernetes.io/last-applied-configuration=（略）
                        kubernetes.io/change-cause=kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.7
Selector:               app=whoami
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=whoami
  Containers:
   whoami:
    Image:        opera443399/whoami:0.7
    Port:         80/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   test-deployment-app-whoami-68c6cd964 (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  12m   deployment-controller  Scaled up replica set test-deployment-app-whoami-6cf9cd6bf4 to 3
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 1
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 2
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 2
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 1
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 3
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 0


[root@tvm-00 ~]# kubectl rollout history deployments/test-deployment-app-whoami
deployments "test-deployment-app-whoami"
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=/root/k8s_install/test/whoami/app.yaml --record=true
2         kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.7

```

- 再更新 1 次镜像后，再次查看信息
```bash
[root@tvm-00 ~]# kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.8
deployment "test-deployment-app-whoami" image updated
[root@tvm-00 ~]# kubectl rollout status deployments/test-deployment-app-whoami
deployment "test-deployment-app-whoami" successfully rolled out
[root@tvm-00 ~]# kubectl get deployments
NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
test-deployment-app-whoami   3         3         3            3           17m
[root@tvm-00 ~]# kubectl get rs
NAME                                    DESIRED   CURRENT   READY     AGE
test-deployment-app-whoami-68b94dd7bf   3         3         3         46s
test-deployment-app-whoami-68c6cd964    0         0         0         6m
test-deployment-app-whoami-6cf9cd6bf4   0         0         0         17m
[root@tvm-00 ~]# kubectl get pods
NAME                                          READY     STATUS    RESTARTS   AGE
test-deployment-app-whoami-68b94dd7bf-5g89x   1/1       Running   0          45s
test-deployment-app-whoami-68b94dd7bf-75xjd   1/1       Running   0          52s
test-deployment-app-whoami-68b94dd7bf-pchpw   1/1       Running   0          49s
[root@tvm-00 ~]# kubectl describe deployments/test-deployment-app-whoami
Name:                   test-deployment-app-whoami
Namespace:              default
CreationTimestamp:      Wed, 27 Dec 2017 17:44:30 +0800
Labels:                 app=whoami
Annotations:            deployment.kubernetes.io/revision=3
                        kubectl.kubernetes.io/last-applied-configuration=（略）
                        kubernetes.io/change-cause=kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.8
Selector:               app=whoami
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=whoami
  Containers:
   whoami:
    Image:        opera443399/whoami:0.8
    Port:         80/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   test-deployment-app-whoami-68b94dd7bf (3/3 replicas created)
Events:
  Type    Reason             Age              From                   Message
  ----    ------             ----             ----                   -------
  Normal  ScalingReplicaSet  18m              deployment-controller  Scaled up replica set test-deployment-app-whoami-6cf9cd6bf4 to 3
  Normal  ScalingReplicaSet  7m               deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 1
  Normal  ScalingReplicaSet  7m               deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 2
  Normal  ScalingReplicaSet  7m               deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 2
  Normal  ScalingReplicaSet  7m               deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 1
  Normal  ScalingReplicaSet  7m               deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 3
  Normal  ScalingReplicaSet  7m               deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 0
  Normal  ScalingReplicaSet  2m               deployment-controller  Scaled up replica set test-deployment-app-whoami-68b94dd7bf to 1
  Normal  ScalingReplicaSet  2m               deployment-controller  Scaled down replica set test-deployment-app-whoami-68c6cd964 to 2
  Normal  ScalingReplicaSet  2m               deployment-controller  Scaled up replica set test-deployment-app-whoami-68b94dd7bf to 2
  Normal  ScalingReplicaSet  2m (x3 over 2m)  deployment-controller  (combined from similar events): Scaled down replica set test-deployment-app-whoami-68c6cd964 to 0
[root@tvm-00 ~]# kubectl rollout history deployments/test-deployment-app-whoami
deployments "test-deployment-app-whoami"
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=/root/k8s_install/test/whoami/app.yaml --record=true
2         kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.7
3         kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.8

### 符合预期，我们现在有了 3 个版本
```

##### 回滚 app
- 回滚到上一个版本
```bash
[root@tvm-00 ~]# kubectl rollout undo deployments/test-deployment-app-whoami
deployment "test-deployment-app-whoami"
[root@tvm-00 ~]# kubectl rollout history deployments/test-deployment-app-whoami
deployments "test-deployment-app-whoami"
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=/root/k8s_install/test/whoami/app.yaml --record=true
3         kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.8
4         kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.7


[root@tvm-00 ~]# kubectl get rs
NAME                                    DESIRED   CURRENT   READY     AGE
test-deployment-app-whoami-68b94dd7bf   0         0         0         16m
test-deployment-app-whoami-68c6cd964    3         3         3         22m
test-deployment-app-whoami-6cf9cd6bf4   0         0         0         33m

[root@tvm-00 ~]# kubectl describe deployments/test-deployment-app-whoami
Name:                   test-deployment-app-whoami
Namespace:              default
CreationTimestamp:      Wed, 27 Dec 2017 17:44:30 +0800
Labels:                 app=whoami
Annotations:            deployment.kubernetes.io/revision=4
                        kubectl.kubernetes.io/last-applied-configuration=（略）
                        kubernetes.io/change-cause=kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.7
Selector:               app=whoami
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=whoami
  Containers:
   whoami:
    Image:        opera443399/whoami:0.7
    Port:         80/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   test-deployment-app-whoami-68c6cd964 (3/3 replicas created)
Events:
  Type    Reason              Age               From                   Message
  ----    ------              ----              ----                   -------
  Normal  ScalingReplicaSet   27m               deployment-controller  Scaled up replica set test-deployment-app-whoami-6cf9cd6bf4 to 3
  Normal  ScalingReplicaSet   17m               deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 2
  Normal  ScalingReplicaSet   17m               deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 2
  Normal  ScalingReplicaSet   17m               deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 1
  Normal  ScalingReplicaSet   17m               deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 3
  Normal  ScalingReplicaSet   16m               deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 0
  Normal  ScalingReplicaSet   11m               deployment-controller  Scaled up replica set test-deployment-app-whoami-68b94dd7bf to 1
  Normal  ScalingReplicaSet   11m               deployment-controller  Scaled down replica set test-deployment-app-whoami-68c6cd964 to 2
  Normal  ScalingReplicaSet   11m               deployment-controller  Scaled up replica set test-deployment-app-whoami-68b94dd7bf to 2
  Normal  ScalingReplicaSet   1m (x2 over 17m)  deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 1
  Normal  DeploymentRollback  1m                deployment-controller  Rolled back deployment "test-deployment-app-whoami" to revision 2
  Normal  ScalingReplicaSet   1m (x8 over 11m)  deployment-controller  (combined from similar events): Scaled down replica set test-deployment-app-whoami-68b94dd7bf to 0
```

- 回滚到指定的版本
```bash
[root@tvm-00 ~]# kubectl rollout undo deployments/test-deployment-app-whoami --to-revision=1
deployment "test-deployment-app-whoami"
[root@tvm-00 ~]# kubectl rollout history deployments/test-deployment-app-whoami
deployments "test-deployment-app-whoami"
REVISION  CHANGE-CAUSE
3         kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.8
4         kubectl set image deployments/test-deployment-app-whoami whoami=opera443399/whoami:0.7
5         kubectl apply --filename=/root/k8s_install/test/whoami/app.yaml --record=true


[root@tvm-00 ~]# kubectl get rs
NAME                                    DESIRED   CURRENT   READY     AGE
test-deployment-app-whoami-68b94dd7bf   0         0         0         16m
test-deployment-app-whoami-68c6cd964    0         0         0         22m
test-deployment-app-whoami-6cf9cd6bf4   3         3         3         33m

[root@tvm-00 ~]# kubectl describe deployments/test-deployment-app-whoami
Name:                   test-deployment-app-whoami
Namespace:              default
CreationTimestamp:      Wed, 27 Dec 2017 17:44:30 +0800
Labels:                 app=whoami
Annotations:            deployment.kubernetes.io/revision=5
                        kubectl.kubernetes.io/last-applied-configuration=（略）
                        kubernetes.io/change-cause=kubectl apply --filename=/root/k8s_install/test/whoami/app.yaml --record=true
Selector:               app=whoami
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=whoami
  Containers:
   whoami:
    Image:        opera443399/whoami:0.9
    Port:         80/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   test-deployment-app-whoami-6cf9cd6bf4 (3/3 replicas created)
Events:
  Type    Reason              Age                 From                   Message
  ----    ------              ----                ----                   -------
  Normal  ScalingReplicaSet   29m                 deployment-controller  Scaled up replica set test-deployment-app-whoami-6cf9cd6bf4 to 3
  Normal  ScalingReplicaSet   19m                 deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 2
  Normal  ScalingReplicaSet   19m                 deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 2
  Normal  ScalingReplicaSet   19m                 deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 1
  Normal  ScalingReplicaSet   19m                 deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 3
  Normal  ScalingReplicaSet   19m                 deployment-controller  Scaled down replica set test-deployment-app-whoami-6cf9cd6bf4 to 0
  Normal  ScalingReplicaSet   13m                 deployment-controller  Scaled up replica set test-deployment-app-whoami-68b94dd7bf to 1
  Normal  ScalingReplicaSet   13m                 deployment-controller  Scaled down replica set test-deployment-app-whoami-68c6cd964 to 2
  Normal  ScalingReplicaSet   13m                 deployment-controller  Scaled up replica set test-deployment-app-whoami-68b94dd7bf to 2
  Normal  ScalingReplicaSet   3m (x2 over 19m)    deployment-controller  Scaled up replica set test-deployment-app-whoami-68c6cd964 to 1
  Normal  DeploymentRollback  3m                  deployment-controller  Rolled back deployment "test-deployment-app-whoami" to revision 2
  Normal  DeploymentRollback  29s                 deployment-controller  Rolled back deployment "test-deployment-app-whoami" to revision 1
  Normal  ScalingReplicaSet   27s (x12 over 13m)  deployment-controller  (combined from similar events): Scaled up replica set test-deployment-app-whoami-6cf9cd6bf4 to 3
  Normal  ScalingReplicaSet   27s                 deployment-controller  Scaled down replica set test-deployment-app-whoami-68c6cd964 to 1
  Normal  ScalingReplicaSet   26s                 deployment-controller  Scaled down replica set test-deployment-app-whoami-68c6cd964 to 0
```

##### 扩缩容 app
- 扩容
```bash
### 调整副本数量到 10 个
[root@tvm-00 ~]# kubectl scale deployments/test-deployment-app-whoami --replicas=10
deployment "test-deployment-app-whoami" scaled

### 查看信息
[root@tvm-00 ~]# kubectl get deployments
NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
test-deployment-app-whoami   10        10        10           10          39m
[root@tvm-00 ~]# kubectl get rs
NAME                                    DESIRED   CURRENT   READY     AGE
test-deployment-app-whoami-68b94dd7bf   0         0         0         23m
test-deployment-app-whoami-68c6cd964    0         0         0         29m
test-deployment-app-whoami-6cf9cd6bf4   10        10        10        39m
[root@tvm-00 ~]# kubectl get pods
NAME                                          READY     STATUS    RESTARTS   AGE
test-deployment-app-whoami-6cf9cd6bf4-2dd5m   1/1       Running   0          36s
test-deployment-app-whoami-6cf9cd6bf4-4nx7x   1/1       Running   0          36s
test-deployment-app-whoami-6cf9cd6bf4-bb7v7   1/1       Running   0          10m
test-deployment-app-whoami-6cf9cd6bf4-c7cht   1/1       Running   0          36s
test-deployment-app-whoami-6cf9cd6bf4-dph22   1/1       Running   0          36s
test-deployment-app-whoami-6cf9cd6bf4-jhtqz   1/1       Running   0          10m
test-deployment-app-whoami-6cf9cd6bf4-jjfp5   1/1       Running   0          36s
test-deployment-app-whoami-6cf9cd6bf4-nlqq5   1/1       Running   0          36s
test-deployment-app-whoami-6cf9cd6bf4-px24h   1/1       Running   0          10m
test-deployment-app-whoami-6cf9cd6bf4-rldhd   1/1       Running   0          36s
```

- 缩容
```bash
### 调整副本数量到 5 个
[root@tvm-00 ~]# kubectl scale deployments/test-deployment-app-whoami --replicas=5
deployment "test-deployment-app-whoami" scaled

### 查看信息
[root@tvm-00 ~]# kubectl get deployments
NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
test-deployment-app-whoami   5         5         5            5           41m
[root@tvm-00 ~]# kubectl get rs
NAME                                    DESIRED   CURRENT   READY     AGE
test-deployment-app-whoami-68b94dd7bf   0         0         0         25m
test-deployment-app-whoami-68c6cd964    0         0         0         30m
test-deployment-app-whoami-6cf9cd6bf4   5         5         5         41m
[root@tvm-00 ~]# kubectl get pods
NAME                                          READY     STATUS    RESTARTS   AGE
test-deployment-app-whoami-6cf9cd6bf4-2dd5m   1/1       Running   0          2m
test-deployment-app-whoami-6cf9cd6bf4-bb7v7   1/1       Running   0          12m
test-deployment-app-whoami-6cf9cd6bf4-c7cht   1/1       Running   0          2m
test-deployment-app-whoami-6cf9cd6bf4-jhtqz   1/1       Running   0          12m
test-deployment-app-whoami-6cf9cd6bf4-px24h   1/1       Running   0          12m
```

##### 删除
```bash
[root@tvm-00 test]# kubectl delete deployments/test-deployment-app-whoami
deployment "test-deployment-app-whoami" deleted
[root@tvm-00 test]# kubectl get deployments
No resources found.
```
