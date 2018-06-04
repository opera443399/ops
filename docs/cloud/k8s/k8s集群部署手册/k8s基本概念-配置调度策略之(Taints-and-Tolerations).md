# k8s基本概念-配置调度策略之(Taints-and-Tolerations)
2018/4/12

### 通过定义 Taints and Tolerations 来达到 node 排斥 pod 的目的
* 通过一个典型实例来描述 taint 和 toleration 之间的关联
  - 测试前的集群状态
  - 部署app `whoami-t1`
  - 测试 taint 的用法
  - 测试结果
  - 测试使用 `toleration`
  - 测试结果
  - 如何移除指定的 taint 呢？
* 聊一聊 Taints and Tolerations 的细节
  - 概念


### 通过一个典型实例来描述 taint 和 toleration 之间的关联
##### 测试前的集群状态
部署集群的时候，你极可能有留意到，集群中设置为 master 角色的节点，是不会有任务调度到这里来执行的，这是为何呢？
```bash
[root@tvm-02 whoami]# kubectl get nodes
NAME     STATUS    ROLES     AGE       VERSION
tvm-01   Ready     master    8d        v1.9.0
tvm-02   Ready     master    8d        v1.9.0
tvm-03   Ready     master    8d        v1.9.0
tvm-04   Ready     <none>    8d        v1.9.0
[root@tvm-02 whoami]# kubectl describe nodes tvm-01 |grep -E '(Roles|Taints)'
Roles:              master
Taints:             node-role.kubernetes.io/master:NoSchedule
[root@tvm-02 whoami]# kubectl describe nodes tvm-02 |grep -E '(Roles|Taints)'
Roles:              master
Taints:             node-role.kubernetes.io/master:NoSchedule
[root@tvm-02 whoami]# kubectl describe nodes tvm-03 |grep -E '(Roles|Taints)'
Roles:              master
Taints:             node-role.kubernetes.io/master:NoSchedule
```

##### 部署app `whoami-t1`
```yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: whoami-t1
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

> 部署后可以发现，所有任务都被调度到 worker 节点上
```bash
[root@tvm-02 whoami]# kubectl apply -f app-t1.yaml
deployment "whoami-t1" created
[root@tvm-02 whoami]# kubectl get ds,deploy,svc,pods --all-namespaces -o wide -l app=whoami
NAMESPACE   NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES                   SELECTOR
default     deploy/whoami-t1   3         3         3            3           46s       whoami       opera443399/whoami:0.9   app=whoami

NAMESPACE   NAME                            READY     STATUS    RESTARTS   AGE       IP             NODE
default     po/whoami-t1-6cf9cd6bf4-62bhc   1/1       Running   0          46s       172.30.105.1   tvm-04
default     po/whoami-t1-6cf9cd6bf4-dss72   1/1       Running   0          46s       172.30.105.2   tvm-04
default     po/whoami-t1-6cf9cd6bf4-zvpsk   1/1       Running   0          46s       172.30.105.0   tvm-04

```


##### 测试 taint 的用法
给 tvm-04 配置一个 taint 来调整调度策略
```bash
[root@tvm-02 whoami]# kubectl taint nodes tvm-04 node-role.kubernetes.io/master=:NoSchedule
node "tvm-04" tainted
##### 符合预期
[root@tvm-02 whoami]# kubectl describe nodes tvm-04 |grep -E '(Roles|Taints)'
Roles:              <none>
Taints:             node-role.kubernetes.io/master:NoSchedule

```
> 上述 taint 的指令含义是：
> 给节点 `tvm-04` 配置一个 taint （可以理解为：污点）
> 其中，这个 taint 的
> key 是 `node-role.kubernetes.io/master`
> value 是 `` （值为空）
> taint effect 是 `NoSchedule`
> 这意味着，没有任何 pod 可以调度到这个节点上面，除非在这个 pod 的描述文件中有一个对应的 `toleration` （可以理解为：设置 pod 容忍了这个污点）


##### 测试结果
我们发现，之前部署的 `deploy/whoami-t1` 并未被驱逐
```bash
[root@tvm-02 whoami]# kubectl get ds,deploy,svc,pods --all-namespaces -o wide -l app=whoami
NAMESPACE   NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES                   SELECTOR
default     deploy/whoami-t1   3         3         3            3           17m       whoami       opera443399/whoami:0.9   app=whoami

NAMESPACE   NAME                            READY     STATUS    RESTARTS   AGE       IP             NODE
default     po/whoami-t1-6cf9cd6bf4-62bhc   1/1       Running   0          17m       172.30.105.1   tvm-04
default     po/whoami-t1-6cf9cd6bf4-dss72   1/1       Running   0          17m       172.30.105.2   tvm-04
default     po/whoami-t1-6cf9cd6bf4-zvpsk   1/1       Running   0          17m       172.30.105.0   tvm-04

```

接着我们尝试着再部署一个app `whoami-t2`
```yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: whoami-t2
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
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Equal"
        value: ""
        effect: "NoSched

```

下述操作表明：策略已经生效，只是旧的 deploy 默认不会受到影响（被强制驱逐）
```bash
##### 部署
[root@tvm-02 whoami]# kubectl apply -f app-t2.yaml
deployment "whoami-t2" created
[root@tvm-02 whoami]# kubectl get ds,deploy,svc,pods --all-namespaces -o wide -l app=whoami
NAMESPACE   NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES                   SELECTOR
default     deploy/whoami-t1   3         3         3            3           20m       whoami       opera443399/whoami:0.9   app=whoami
default     deploy/whoami-t2   3         3         3            0           38s       whoami       opera443399/whoami:0.9   app=whoami

NAMESPACE   NAME                            READY     STATUS    RESTARTS   AGE       IP             NODE
default     po/whoami-t1-6cf9cd6bf4-62bhc   1/1       Running   0          20m       172.30.105.1   tvm-04
default     po/whoami-t1-6cf9cd6bf4-dss72   1/1       Running   0          20m       172.30.105.2   tvm-04
default     po/whoami-t1-6cf9cd6bf4-zvpsk   1/1       Running   0          20m       172.30.105.0   tvm-04
default     po/whoami-t2-6cf9cd6bf4-5f9wl   0/1       Pending   0          38s       <none>         <none>
default     po/whoami-t2-6cf9cd6bf4-8l59z   0/1       Pending   0          38s       <none>         <none>
default     po/whoami-t2-6cf9cd6bf4-lqpzp   0/1       Pending   0          38s       <none>         <none>

[root@tvm-02 whoami]# kubectl describe deploy/whoami-t2
Name:                   whoami-t2
(omited)
Annotations:            deployment.kubernetes.io/revision=1
Replicas:               3 desired | 3 updated | 3 total | 0 available | 3 unavailable
(omited)
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      False   MinimumReplicasUnavailable
  Progressing    True    ReplicaSetUpdated
(omited)
[root@tvm-02 whoami]# kubectl describe po/whoami-t2-6cf9cd6bf4-5f9wl
Name:           whoami-t2-6cf9cd6bf4-5f9wl
(omited)
Status:         Pending
IP:
Controlled By:  ReplicaSet/whoami-t2-6cf9cd6bf4
(omited)
Conditions:
  Type           Status
  PodScheduled   False
(omited)
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedScheduling  27s (x14 over 3m)  default-scheduler  0/4 nodes are available: 4 PodToleratesNodeTaints.

```



##### 测试使用 `toleration`
增加 `toleration` 相关的配置来调度 `whoami-t2` 到 `master` 节点上
```yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: whoami-t2
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
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Equal"
        value: ""
        effect: "NoSchedule"
```

##### 测试结果
下述操作表明：之前不可用的节点，调整后，节点处于可用状态， pod 部署成功
```bash
##### 更新
[root@tvm-02 whoami]# kubectl apply -f app-t2.yaml
deployment "whoami-t2" configured
##### 连续 2 次查看状态
[root@tvm-02 whoami]# kubectl describe deploy/whoami-t2
Name:                   whoami-t2
(omitted)
Annotations:            deployment.kubernetes.io/revision=2
Replicas:               3 desired | 3 updated | 4 total | 2 available | 2 unavailable
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      False   MinimumReplicasUnavailable
  Progressing    True    ReplicaSetUpdated
OldReplicaSets:  whoami-t2-6cf9cd6bf4 (1/1 replicas created)
NewReplicaSet:   whoami-t2-647c9cb7c5 (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  39m   deployment-controller  Scaled up replica set whoami-t2-6cf9cd6bf4 to 3
  Normal  ScalingReplicaSet  14s   deployment-controller  Scaled up replica set whoami-t2-647c9cb7c5 to 1
  Normal  ScalingReplicaSet  12s   deployment-controller  Scaled down replica set whoami-t2-6cf9cd6bf4 to 2
  Normal  ScalingReplicaSet  12s   deployment-controller  Scaled up replica set whoami-t2-647c9cb7c5 to 2
  Normal  ScalingReplicaSet  6s    deployment-controller  Scaled down replica set whoami-t2-6cf9cd6bf4 to 1
  Normal  ScalingReplicaSet  6s    deployment-controller  Scaled up replica set whoami-t2-647c9cb7c5 to 3
[root@tvm-02 whoami]# kubectl describe deploy/whoami-t2
Name:                   whoami-t2
(omitted)
Annotations:            deployment.kubernetes.io/revision=2
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
(omitted)
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   whoami-t2-647c9cb7c5 (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  39m   deployment-controller  Scaled up replica set whoami-t2-6cf9cd6bf4 to 3
  Normal  ScalingReplicaSet  28s   deployment-controller  Scaled up replica set whoami-t2-647c9cb7c5 to 1
  Normal  ScalingReplicaSet  26s   deployment-controller  Scaled down replica set whoami-t2-6cf9cd6bf4 to 2
  Normal  ScalingReplicaSet  26s   deployment-controller  Scaled up replica set whoami-t2-647c9cb7c5 to 2
  Normal  ScalingReplicaSet  20s   deployment-controller  Scaled down replica set whoami-t2-6cf9cd6bf4 to 1
  Normal  ScalingReplicaSet  20s   deployment-controller  Scaled up replica set whoami-t2-647c9cb7c5 to 3
  Normal  ScalingReplicaSet  12s   deployment-controller  Scaled down replica set whoami-t2-6cf9cd6bf4 to 0

[root@tvm-02 whoami]# kubectl get ds,deploy,svc,pods --all-namespaces -o wide -l app=whoami
NAMESPACE   NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES                   SELECTOR
default     deploy/whoami-t1   3         3         3            3           1h        whoami       opera443399/whoami:0.9   app=whoami
default     deploy/whoami-t2   3         3         3            3           45m       whoami       opera443399/whoami:0.9   app=whoami

NAMESPACE   NAME                            READY     STATUS    RESTARTS   AGE       IP               NODE
default     po/whoami-t1-6cf9cd6bf4-62bhc   1/1       Running   0          1h        172.30.105.1     tvm-04
default     po/whoami-t1-6cf9cd6bf4-dss72   1/1       Running   0          1h        172.30.105.2     tvm-04
default     po/whoami-t1-6cf9cd6bf4-zvpsk   1/1       Running   0          1h        172.30.105.0     tvm-04
default     po/whoami-t2-647c9cb7c5-9b5b6   1/1       Running   0          6m        172.30.105.3     tvm-04
default     po/whoami-t2-647c9cb7c5-kmj6k   1/1       Running   0          6m        172.30.235.129   tvm-01
default     po/whoami-t2-647c9cb7c5-p5gwm   1/1       Running   0          5m        172.30.60.193    tvm-03

```

##### 如何移除指定的 taint 呢？
```bash
[root@tvm-02 whoami]# kubectl taint nodes tvm-04 node-role.kubernetes.io/master:NoSchedule-
node "tvm-04" untainted
##### 符合预期
[root@tvm-02 whoami]# kubectl describe nodes tvm-04 |grep -E '(Roles|Taints)'
Roles:              <none>
Taints:             <none>

```


### 聊一聊 Taints and Tolerations 的细节

> `Taints` 和 `Node affinity` 是对立的概念，用来允许一个 node 拒绝某一类 pods
> `Taints` 和 `tolerations` 配合起来可以保证 pods 不会被调度到不合适的 nodes 上干活
>  一个 node 上可以有多个 `taints`
> 将`tolerations` 应用到 pods 来允许被调度到合适的 nodes 上干活

##### 概念
示范增加一个 taint 到 node 上的操作：
```bash
kubectl taint nodes tvm-04 demo.test.com/app=whoami:NoSchedule
```
在节点 `tvm-04` 上配置了一个 `taint` ，其中：
`key` 是 `demo.test.com/app`
`value` 是 `whoami`
`taint effect` 是 `NoSchedule`

如果要移除 `taint` 则：
```bash
kubectl taint nodes tvm-04 demo.test.com/app:NoSchedule-
```

然后在 `PodSpec` 中定义 `toleration` 使得该 pod 可以被调度到 `tvm-04` 上，有下述 2 种方式：
```yaml
tolerations:
- key: "demo.test.com/app"
  operator: "Equal"
  value: "whoami"
  effect: "NoSchedule"
```
```yaml
tolerations:
- key: "demo.test.com/app"
  operator: "Exists"
  effect: "NoSchedule"
```

`taint` 和 `toleration` 要匹配上，需要满足两者的 `keys` 和 `effects` 是一致的，且：
- 当 `operator` 是 `Exists` （意味着不用指定 `value` 的内容）时，或者
- 当 `operator` 是 `Equal` 时 `values` 也相同

注1： `operator` 默认值是 `Equal` 如果不指定的话

注2: 留意下面 2 个使用 `Exists` 的特例
- key 为空且 `operator` 是 `Exists`  时，将匹配所有的 `keys`, `values` 和 `effects` ，这表明可以 `tolerate` 所有的 `taint`
```yaml
tolerations:
- operator: "Exists"
```

- `effect` 为空将匹配 `demo.test.com/app` 这个 `key` 对应的所有的 `effects`
```bash
tolerations:
- key: "demo.test.com/app"
  operator: "Exists"
```

上述 `effect` 使用的是 `NoSchedule` ，其实还可以使用其他的调度策略，例如：
- PreferNoSchedule ： 这意味着不是一个强制必须的调度策略（尽量不去满足不合要求的 pod 调度到 node 上来）
- NoExecute ： 后续解释

可以在同一个 node 上使用多个 `taints` ，也可以在同一个 pod 上使用多个 `tolerations` ，而 k8s 在处理 `taints and tolerations` 时类似一个过滤器：
- 对比一个 node 上所有的 `taints`
- 忽略掉和 pod 中 `toleration` 匹配的 `taints`
- 遗留下来未被忽略掉的所有 `taints` 将对 pod 产生 `effect`

尤其是：
- 至少有 1 个未被忽略的 `taint` 且 `effect` 是 `NoSchedule` 时，则 k8s 不会将该 pod 调度到这个 node 上
- 不满足上述场景，但至少有 1 个未被忽略的 `taint` 且 `effect` 是 `PreferNoSchedule` 时，则 k8s 将尝试不把该 pod 调度到这个 node 上
- 至少有 1 个未被忽略的 `taint` 且 `effect` 是 `NoExecute` 时，则 k8s 会立即将该 pod 从该 node 上驱逐（如果已经在该 node 上运行），或着不会将该 pod 调度到这个 node 上（如果还没在这个 node 上运行）


**实例**，有下述 node 和 pod 的定义：
```bash
kubectl taint nodes tvm-04 key1=value1:NoSchedule
kubectl taint nodes tvm-04 key1=value1:NoExecute
kubectl taint nodes tvm-04 key2=value2:NoSchedule
```
```yaml
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoExecute"
```
上述场景中，
- 该 pod 不会调度到 node 上，因为第 3 个 taint 不满足
- 如果该 pod 已经在该 node 上运行，则不会被驱逐

通常而言，不能 `tolerate` 一个 `effect` 是 `NoExecute` 的 pod 将被立即驱逐，但是，通过指定可选的字段 `tolerationSeconds` 则可以规定该 pod 延迟到一个时间段后再被驱逐，例如：
```yaml
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoExecute"
  tolerationSeconds: 3600
```

也就是说，在 3600 秒后将被驱逐。但是，如果在这个时间点前移除了相关的 `taint` 则也不会被驱逐
注3：关于被驱逐，如果该 pod 没有其他地方可以被调度，也不会被驱逐出去（个人实验结果，请自行验证）



### ZYXW、参考
1. [Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
