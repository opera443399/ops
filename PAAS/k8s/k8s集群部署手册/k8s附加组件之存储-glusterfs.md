# k8s附加组件之存储-glusterfs
2018/2/1

### 部署 glusterfs 集群
  - 初始化 glusterfs 集群
  - 创建 glusterfs 卷，用于保存数据

##### 不做特别说明的，都在 67 上操作
集群节点
  - 10.10.9.67
  - 10.10.9.68
  - 10.10.9.69

##### 初始化 glusterfs 集群
```bash
~]# yum install centos-release-gluster310 -y
~]# yum install glusterfs-server -y
~]# yum install xfsprogs -y

##### 准备磁盘：
~]# umount /data1
~]# mkfs.xfs -i size=512 -f /dev/vdc1
~]# mount /dev/vdc1 /data1
~]# vim /etc/fstab
### glusterfs
/dev/vdc1 /data1                       xfs    defaults        0 0


##### 启动服务：
~]# systemctl start glusterd && systemctl enable glusterd

##### 建立集群：
~]# gluster peer probe 10.10.9.68
~]# gluster peer probe 10.10.9.69
~]# gluster peer status


##### 在所有节点操作：
~]# mkdir /data1/glusterfs_data/gv0 -p && \
echo '### glusterfs data for k8s-dev only!' >/data1/glusterfs_data/README.md
```

##### 创建 glusterfs 卷，用于保存数据
```bash
~]# gluster volume create gv0 replica 3 transport tcp \
10.10.9.67:/data1/glusterfs_data/gv0 \
10.10.9.68:/data1/glusterfs_data/gv0 \
10.10.9.69:/data1/glusterfs_data/gv0
~]# gluster volume start gv0
~]# gluster volume info gv0

##### 配置参数，特别是 quorum 相关的，用于预防脑裂问题
gluster volume set gv0 diagnostics.count-fop-hits on
gluster volume set gv0 diagnostics.latency-measurement on
gluster volume set gv0 cluster.server-quorum-type server
gluster volume set gv0 cluster.quorum-type auto
gluster volume set gv0 network.remote-dio enable
gluster volume set gv0 cluster.eager-lock enable
gluster volume set gv0 performance.stat-prefetch off
gluster volume set gv0 performance.io-cache off
gluster volume set gv0 performance.read-ahead off
gluster volume set gv0 performance.quick-read off

##### 在客户端上配置 glusterfs 环境并挂载测试
~]# yum install centos-release-gluster310 -y
~]# yum install glusterfs glusterfs-fuse -y
~]# mkdir /mnt/test
~]# mount -t glusterfs -o backup-volfile-servers=10.10.9.68:10.10.9.69 10.10.9.67:/gv0 /mnt/test
~]# df -h |grep test
10.10.9.67:/gv0  1.0T   33M  1.0T   1% /mnt/test
~]# umount /mnt/test

```


### 准备 k8s yaml 来使用 glusterfs 集群
  - 创建一个数据卷
  - 通过定义 endpoints 和 service 来提供访问外部服务（glusterfs集群）的方法
  - 通过定义 pv 和 pvc 来使用存储卷
  - 测试，在 deployment 中通过关联 pvc 来挂载卷
  - 测试，多副本读写同一个日志文件的场景


##### 创建一个数据卷
```bash
[root@tvm-00 glusterfs]# ls
10.endpoints  20.pv  30.pvc  bin  deploy_test

[root@tvm-00 glusterfs]# cat bin/create-gv1-default.sh
#!/bin/bash
#

gluster volume create gv1-default replica 3 transport tcp \
10.10.9.67:/data1/glusterfs_data/gv1-default \
10.10.9.68:/data1/glusterfs_data/gv1-default \
10.10.9.69:/data1/glusterfs_data/gv1-default
gluster volume start gv1-default
gluster volume info gv1-default

```

##### 通过定义 endpoints 和 service 来提供访问外部服务（glusterfs集群）的方法
```bash
[root@tvm-00 glusterfs]# cat 10.endpoints/glusterfs-r3/default.yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: glusterfs-r3
  namespace: default
subsets:
- addresses:
  - ip: 10.10.9.67
  - ip: 10.10.9.68
  - ip: 10.10.9.69
  ports:
  - port: 49152
    protocol: TCP

---
apiVersion: v1
kind: Service
metadata:
  name: glusterfs-r3
  namespace: default
spec:
  ports:
  - port: 49152
    protocol: TCP
    targetPort: 49152
  sessionAffinity: None
  type: ClusterIP

[root@tvm-00 glusterfs]# kubectl apply -f 10.endpoints/glusterfs-r3/default.yaml

##### 查看状态：
[root@tvm-00 glusterfs]# kubectl get ep glusterfs-r3
NAME           ENDPOINTS                                            AGE
glusterfs-r3   10.10.9.67:49152,10.10.9.68:49152,10.10.9.69:49152   4h

```


##### 通过定义 pv 和 pvc 来使用存储卷
```bash
##### 注意：pv 是不区分 namespace 的资源，但又和不同 namespace 下的资源交互，此处有点奇怪，不知为何如此设计
[root@tvm-00 glusterfs]# cat 20.pv/glusterfs-r3/gv1-default.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: glusterfs-r3-gv1-default
  labels:
    type: glusterfs
spec:
  storageClassName: gv1-default
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  glusterfs:
    endpoints: "glusterfs-r3"
    path: "gv1-default"
    readOnly: false

[root@tvm-00 glusterfs]# cat 30.pvc/glusterfs-r3/gv1-default.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: glusterfs-r3-gv1-default
  namespace: default
spec:
  storageClassName: gv1-default
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi

[root@tvm-00 glusterfs]# kubectl apply -f 20.pv/glusterfs-r3/gv1-default.yaml
[root@tvm-00 glusterfs]# kubectl apply -f 30.pvc/glusterfs-r3/gv1-default.yaml

##### 查看状态：
[root@tvm-00 glusterfs]# kubectl get pv,pvc
NAME                               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                        STORAGECLASS       REASON    AGE
pv/glusterfs-r3-gv1-default        100Gi      RWX            Retain           Bound     default/glusterfs-r3-gv1-default             gv1-default                  46m


NAME                           STATUS    VOLUME                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc/glusterfs-r3-gv1-default   Bound     glusterfs-r3-gv1-default   100Gi      RWX            gv1-default    44m

```

##### 测试，在 deployment 中通过关联 pvc 来挂载卷
```bash
[root@tvm-00 glusterfs]# cat deploy_test/gv1-default-t1.yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: gv1-default-t1
  namespace: default
  labels:
    app.name: gv1-default-t1
spec:
  replicas: 1
  selector:
    matchLabels:
      app.name: gv1-default-t1
  template:
    metadata:
      labels:
        app.name: gv1-default-t1
    spec:
      containers:
      - name: nginx-test
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: glusterfsvol
          mountPath: "/mnt/glusterfsvol"
      volumes:
      - name: glusterfsvol
        persistentVolumeClaim:
          claimName: glusterfs-r3-gv1-default

[root@tvm-00 glusterfs]# kubectl apply -f deploy_test/gv1-default-t1.yaml --record

##### 查看状态：
[root@tvm-00 glusterfs]# kubectl get deploy,po
NAME                    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/gv1-default-t1   1         1         1            1           33s

NAME                                 READY     STATUS    RESTARTS   AGE
po/gv1-default-t1-848455b8b6-fldkb   1/1       Running   0          33s

##### 验证挂载的数据盘：
[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-fldkb -- mount | grep gluster
10.10.9.67:gv1-default on /mnt/glusterfsvol type fuse.glusterfs (rw,relatime,user_id=0,group_id=0,default_permissions,allow_other,max_read=131072)

[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-fldkb -- df -h | grep glusterfsvol
10.10.9.67:gv1-default  1.0T   33M  1.0T   1% /mnt/glusterfsvol

[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-fldkb -- ls -l /mnt/glusterfsvol
total 0

##### 读写测试：
[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-fldkb -- sh -c 'echo " [$(date)] writeFrom: $(hostname)" >>/mnt/glusterfsvol/README.md'

[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-fldkb -- cat /mnt/glusterfsvol/README.md
 [Tue Jan 16 09:50:01 UTC 2018] writeFrom: gv1-default-t1-848455b8b6-fldkb
 [Tue Jan 16 09:50:40 UTC 2018] writeFrom: gv1-default-t1-848455b8b6-fldkb

##### 符合预期

```

##### 测试，多副本读写同一个日志文件的场景
```bash
##### 之前测试的都是 1 个 pod 副本的场景，现在，我们扩容到 3 个副本，然后再看看读写状况：
  replicas: 1
  ->
  replicas: 3
[root@tvm-00 glusterfs]# kubectl scale --replicas=3 -f deploy_test/gv1-default-t1.yaml

##### 查看状态：
[root@tvm-00 glusterfs]# kubectl get deploy,po
NAME                    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/gv1-default-t1   3         3         3            3           20m

NAME                                 READY     STATUS    RESTARTS   AGE
po/gv1-default-t1-848455b8b6-fldkb   1/1       Running   0          20m
po/gv1-default-t1-848455b8b6-gzd4s   1/1       Running   0          1m
po/gv1-default-t1-848455b8b6-t6bsk   1/1       Running   0          1m


##### 分别在 3 个 pod 中往同一个文件写入一条数据
[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-fldkb -- sh -c 'echo " [$(date)] writeFrom: $(hostname)" >>/mnt/glusterfsvol/README.md'
[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-gzd4s -- sh -c 'echo " [$(date)] writeFrom: $(hostname)" >>/mnt/glusterfsvol/README.md'
[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-t6bsk -- sh -c 'echo " [$(date)] writeFrom: $(hostname)" >>/mnt/glusterfsvol/README.md'

##### 验证：
[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-fldkb -- cat /mnt/glusterfsvol/README.md
 [Tue Jan 16 09:50:01 UTC 2018] writeFrom: gv1-default-t1-848455b8b6-fldkb
 [Tue Jan 16 09:50:40 UTC 2018] writeFrom: gv1-default-t1-848455b8b6-fldkb
 [Tue Jan 16 09:55:53 UTC 2018] writeFrom: gv1-default-t1-848455b8b6-fldkb
 [Tue Jan 16 09:55:59 UTC 2018] writeFrom: gv1-default-t1-848455b8b6-gzd4s
 [Tue Jan 16 09:56:04 UTC 2018] writeFrom: gv1-default-t1-848455b8b6-t6bsk

##### 符合预期，但有一个细节请注意，，如何合理的记录日志以便于区分某条记录是来自哪一个 pod 实例？
##### 答案是：写入日志时，业务层应提取类似 hostname 那样的标志符来写入日志中
[root@tvm-00 glusterfs]# kubectl exec gv1-default-t1-848455b8b6-t6bsk -- hostname
gv1-default-t1-848455b8b6-t6bsk


```


##### 如何快速的为指定 namespace 部署一个 volume
```bash

##### 目标：
##### namespace=ns-test1

##### 准备：
cp -a bin/create-gv1-default.sh bin/create-gv1-ns-test1.sh
sed -i 's/default/ns-test1/g' bin/create-gv1-ns-test1.sh
sh bin/create-gv1-ns-test1.sh

cp -a 10.endpoints/glusterfs-r3/default.yaml 10.endpoints/glusterfs-r3/ns-test1.yaml
sed -i 's/default/ns-test1/g' 10.endpoints/glusterfs-r3/ns-test1.yaml

cp -a 20.pv/glusterfs-r3/gv1-default.yaml 20.pv/glusterfs-r3/gv1-ns-test1.yaml
sed -i 's/default/ns-test1/g' 20.pv/glusterfs-r3/gv1-ns-test1.yaml

cp -a 30.pvc/glusterfs-r3/gv1-default.yaml 30.pvc/glusterfs-r3/gv1-ns-test1.yaml
sed -i 's/default/ns-test1/g' 30.pvc/glusterfs-r3/gv1-ns-test1.yaml

cp -a deploy_test/gv1-default-t1.yaml deploy_test/gv1-ns-test1-t1.yaml
sed -i 's/default/ns-test1/g' deploy_test/gv1-ns-test1-t1.yaml

##### 部署：
kubectl apply -f 10.endpoints/glusterfs-r3/ns-test1.yaml
kubectl apply -f 20.pv/glusterfs-r3/gv1-ns-test1.yaml
kubectl apply -f 30.pvc/glusterfs-r3/gv1-ns-test1.yaml
kubectl apply -f deploy_test/gv1-ns-test1-t1.yaml


##### 验证：
[root@tvm-00 glusterfs]# kubectl -n ns-test1 get ep,svc |grep 'glusterfs-r3'
ep/glusterfs-r3                   10.10.9.67:49152,10.10.9.68:49152,10.10.9.69:49152   2m

svc/glusterfs-r3                   ClusterIP   10.107.81.35     <none>        49152/TCP        2m

[root@tvm-00 glusterfs]# kubectl -n ns-test1 get pv,pvc |grep 'ns-test1'
pv/glusterfs-r3-gv1-ns-test1       100Gi      RWX            Retain           Bound     ns-test1/glusterfs-r3-gv1-ns-test1           gv1-ns-test1                 2m

pvc/glusterfs-r3-gv1-ns-test1   Bound     glusterfs-r3-gv1-ns-test1   100Gi      RWX            gv1-ns-test1   2m

[root@tvm-00 glusterfs]# kubectl -n ns-test1 get deploy,po |grep 'ns-test1'

deploy/gv1-ns-test1-t1                1         1         1            1           3m
po/gv1-ns-test1-t1-7f986bfbf8-v5zmz               1/1       Running   0          3m

[root@tvm-00 glusterfs]# kubectl -n ns-test1 exec gv1-ns-test1-t1-7f986bfbf8-v5zmz -- df -h |grep gluster
10.10.9.67:gv1-ns-test1  1.0T   36M  1.0T   1% /mnt/glusterfsvol


```




### ZYXW、参考
1. [glusterfs](https://download.gluster.org/pub/gluster/glusterfs/3.10/LATEST/CentOS/)
2. [CentOS Storage](https://wiki.centos.org/SpecialInterestGroup/Storage)
3. [k8s-glusterfs](https://github.com/kubernetes/examples/tree/master/staging/volumes/glusterfs)
4. [使用glusterfs做持久化存储](https://github.com/rootsongjc/kubernetes-handbook/blob/master/practice/using-glusterfs-for-persistent-storage.md)
