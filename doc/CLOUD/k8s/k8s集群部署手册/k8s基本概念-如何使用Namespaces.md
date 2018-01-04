# k8s基本概念-如何使用Namespaces
2017/12/28


### Namespaces 使用示例
  - Viewing namespaces
  - Creating a new namespace
  - Deleting a namespace
  - Subdividing your cluster using Kubernetes namespaces

##### Viewing namespaces
```bash
[root@tvm-00 test]# kubectl get namespaces
NAME          STATUS    AGE
default       Active    5d
kube-public   Active    5d
kube-system   Active    5d
```

##### Creating a new namespace
```bash
[root@tvm-00 ~]# cat ~/k8s_install/test/ns/dev.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ns-dev
  labels:
    name: envDev

[root@tvm-00 ~]# kubectl apply -f ~/k8s_install/test/ns/dev.yaml
namespace "ns-dev" created

[root@tvm-00 ~]# kubectl get ns
NAME          STATUS    AGE
default       Active    5d
kube-public   Active    5d
kube-system   Active    5d
ns-dev        Active    26s

[root@tvm-00 ~]# kubectl describe namespaces/ns-dev
Name:         ns-dev
Labels:       name=envDev
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Namespace","metadata":{"annotations":{},"labels":{"name":"envDev"},"name":"ns-dev","namespace":""}}

Status:  Active

No resource quota.

No resource limits.
```

##### Deleting a namespace
```bash
[root@tvm-00 ~]# kubectl delete namespaces/ns-dev
namespace "ns-dev" deleted
[root@tvm-00 ~]# kubectl get ns
NAME          STATUS        AGE
default       Active        5d
kube-public   Active        5d
kube-system   Active        5d
ns-dev        Terminating   1m
[root@tvm-00 ~]# kubectl get ns
NAME          STATUS    AGE
default       Active    5d
kube-public   Active    5d
kube-system   Active    5d
```

##### Subdividing your cluster using Kubernetes namespaces
```bash
### 创建 2 个环境 envDev, envTest
[root@tvm-00 ~]# cat ~/k8s_install/test/ns/test.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ns-test
  labels:
    name: envTest
[root@tvm-00 ~]# kubectl apply -f ~/k8s_install/test/ns/dev.yaml
[root@tvm-00 ~]# kubectl apply -f ~/k8s_install/test/ns/test.yaml

[root@tvm-00 ~]# kubectl get ns --show-labels
NAME          STATUS    AGE       LABELS
default       Active    5d        <none>
kube-public   Active    5d        <none>
kube-system   Active    5d        <none>
ns-dev        Active    7m        name=envDev
ns-test       Active    2m        name=envTest


### 假设我们要将服务 s1 的版本 0.9 发布到 envDev，服务 s1 的版本 0.7 发布到 envTest
[root@tvm-00 ~]# kubectl -n ns-dev run s1 --image=opera443399/whoami:0.9 --replicas=2
deployment "s1" created
[root@tvm-00 ~]# kubectl get deploy
NAME         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
app-whoami   3         3         3            3           1h
[root@tvm-00 ~]# kubectl get deploy -n ns-dev
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
s1        2         2         2            2           18s
[root@tvm-00 ~]# kubectl -n ns-test run s1 --image=opera443399/whoami:0.7 --replicas=2
deployment "s1" created
[root@tvm-00 ~]# kubectl get deploy -n ns-test
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
s1        2         2         2            2           10s

[root@tvm-00 ~]# kubectl -n ns-dev describe deploy -l run=s1 |grep Image
    Image:        opera443399/whoami:0.9
[root@tvm-00 ~]# kubectl -n ns-test describe deploy -l run=s1 |grep Image
    Image:        opera443399/whoami:0.7

[root@tvm-00 ~]# kubectl -n ns-dev expose deployments/s1 --type="NodePort" --port 80
service "s1" exposed
[root@tvm-00 ~]# kubectl -n ns-test expose deployments/s1 --type="NodePort" --port 80
service "s1" exposed

[root@tvm-00 ~]# kubectl -n ns-dev get services
NAME      TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
s1        NodePort   10.97.87.8   <none>        80:31176/TCP   28s
[root@tvm-00 ~]# kubectl -n ns-test get services
NAME      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
s1        NodePort   10.98.122.214   <none>        80:30946/TCP   26s

[root@tvm-00 ~]# curl -s tvm-00:31176 |grep version
[howto] version: 0.9
[root@tvm-00 ~]# curl -s tvm-00:30946 |grep version
[howto] version: 0.7

```
