# k8s附加组件之UI-如何使用dashboard
2018/1/4


##### 准备 kubernetes-dashboard 所需资源
```bash
[root@tvm-00 ~]# mkdir -p ~/k8s_install/master/ui
[root@tvm-00 ~]# cd !$
[root@tvm-00 ui]# curl -s -o c https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
[root@tvm-00 ui]# grep image kubernetes-dashboard.yaml
        image: k8s.gcr.io/kubernetes-dashboard-amd64:v1.8.1

### 要确保网络能下载该镜像（略过）


### 调整定义 service 的这一段，发布一个端口出来，例如 nodePort: 30443
[root@tvm-00 ui]# vim kubernetes-dashboard.yaml
（略）
# ------------------- Dashboard Service ------------------- #

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30443
  type: NodePort
  selector:
    k8s-app: kubernetes-dashboard

```

##### 部署
```bash
[root@tvm-00 ui]# kubectl apply -f kubernetes-dashboard.yaml

```

##### 用户和访问
```bash
[root@tvm-00 ui]# cat user-admin.yaml
# ------------------- ServiceAccount ------------------- #

apiVersion: v1
kind: ServiceAccount
metadata:
  name: user-admin
  namespace: kube-system

---
# ------------------- ClusterRoleBinding ------------------- #

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: user-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: user-admin
  namespace: kube-system


[root@tvm-00 ui]# kubectl apply -f user-admin.yaml

### 下面上我们将要用到的 token
[root@tvm-00 ui]# kubectl -n kube-system get secret | grep user-admin
user-admin-token-njqr2                           kubernetes.io/service-account-token   3         2m


[root@tvm-00 ui]# kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep user-admin | awk '{print $1}')
Name:         user-admin-token-njqr2
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name=user-admin
              kubernetes.io/service-account.uid=83e347df-f0f2-11e7-b912-00163e0a6693

Type:  kubernetes.io/service-account-token

Data
====
namespace:  11 bytes
token:      <xxxx>
ca.crt:     1025 bytes

### 将输出的 token 粘贴到 UI 中使用即可

### 访问地址：
https://node_ip_in_cluster:30443/

```



### ZYXW、参考
1. [Kubernetes Dashboard](https://github.com/kubernetes/dashboard#getting-started)
2. [Creating sample user](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user)
