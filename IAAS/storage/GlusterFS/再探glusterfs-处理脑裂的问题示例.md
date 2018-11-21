# 再探glusterfs-处理脑裂的问题示例
2018/2/1


### 在某一次重启整个集群后，某个卷中的文件在客户端访问出现异常
```bash
[root@tvm99 mnt]# echo >test.log
-bash: test.log: Input/output error
```

### 很明显，无法读写文件，应该优先检查脑裂问题
```bash
[root@tvm01 gv1-test1]# gluster volume heal gv1-test1
[root@tvm01 gv1-test1]# gluster volume heal gv1-test1 info
Brick 10.200.50.107:/data1/glusterfs_data/gv1-test1
<gfid:d2ad3781-a4da-482a-86b0-42541d7b37e8> - Is in split-brain

Status: Connected
Number of entries: 1

Brick 10.200.50.108:/data1/glusterfs_data/gv1-test1
<gfid:d2ad3781-a4da-482a-86b0-42541d7b37e8> - Is in split-brain

Status: Connected
Number of entries: 1

Brick 10.200.50.109:/data1/glusterfs_data/gv1-test1
<gfid:d2ad3781-a4da-482a-86b0-42541d7b37e8> - Is in split-brain

Status: Connected
Number of entries: 1


[root@tvm00 ad]# pwd
/data1/glusterfs_data/gv1-test1/.glusterfs/d2/ad
[root@tvm00 ad]# getfattr -d -m . -e hex  d2ad3781-a4da-482a-86b0-42541d7b37e8
# file: d2ad3781-a4da-482a-86b0-42541d7b37e8
trusted.afr.dirty=0x000000000000000000000000
trusted.afr.gv1-test1-client-0=0x000000000000000000000000
trusted.afr.gv1-test1-client-1=0x000000000000000000000000
trusted.afr.gv1-test1-client-2=0x000000040000000000000000
trusted.bit-rot.version=0x04000000000000005a716cdf000c90dd
trusted.gfid=0xd2ad3781a4da482a86b042541d7b37e8

##### 对比一下是否一致
[root@tvm01 ad]# getfattr -d -m . -e hex  d2ad3781-a4da-482a-86b0-42541d7b37e8
# file: d2ad3781-a4da-482a-86b0-42541d7b37e8
trusted.afr.dirty=0x000000000000000000000000
trusted.afr.gv1-test1-client-0=0x000000000000000000000000
trusted.afr.gv1-test1-client-2=0x000000040000000000000000
trusted.bit-rot.version=0x05000000000000005a716d1c0001cb5e
trusted.gfid=0xd2ad3781a4da482a86b042541d7b37e8

[root@tvm02 ad]# getfattr -d -m . -e hex  d2ad3781-a4da-482a-86b0-42541d7b37e8
# file: d2ad3781-a4da-482a-86b0-42541d7b37e8
trusted.afr.dirty=0x000000000000000000000000
trusted.afr.gv1-test1-client-0=0x000000050000000000000000
trusted.afr.gv1-test1-client-1=0x000000070000000000000000
trusted.bit-rot.version=0x03000000000000005a687a2f000856e0
trusted.gfid=0xd2ad3781a4da482a86b042541d7b37e8

##### 分别在 3 个节点设置
[root@tvm00 ad]# setfattr -n trusted.afr.gv1-test1-client-0 -v 0x000000000000000000000000 d2ad3781-a4da-482a-86b0-42541d7b37e8
[root@tvm00 ad]# setfattr -n trusted.afr.gv1-test1-client-1 -v 0x000000000000000000000000 d2ad3781-a4da-482a-86b0-42541d7b37e8
[root@tvm00 ad]# setfattr -n trusted.afr.gv1-test1-client-2 -v 0x000000000000000000000000 d2ad3781-a4da-482a-86b0-42541d7b37e8

##### 符合预期
[root@tvm00 ad]# getfattr -d -m . -e hex  d2ad3781-a4da-482a-86b0-42541d7b37e8
# file: d2ad3781-a4da-482a-86b0-42541d7b37e8
trusted.afr.dirty=0x000000000000000000000000
trusted.afr.gv1-test1-client-0=0x000000000000000000000000
trusted.afr.gv1-test1-client-1=0x000000000000000000000000
trusted.afr.gv1-test1-client-2=0x000000000000000000000000
trusted.bit-rot.version=0x04000000000000005a716cdf000c90dd
trusted.gfid=0xd2ad3781a4da482a86b042541d7b37e8
[root@tvm01 ad]# getfattr -d -m . -e hex  d2ad3781-a4da-482a-86b0-42541d7b37e8
# file: d2ad3781-a4da-482a-86b0-42541d7b37e8
trusted.afr.dirty=0x000000000000000000000000
trusted.afr.gv1-test1-client-0=0x000000000000000000000000
trusted.afr.gv1-test1-client-1=0x000000000000000000000000
trusted.afr.gv1-test1-client-2=0x000000000000000000000000
trusted.bit-rot.version=0x05000000000000005a716d1c0001cb5e
trusted.gfid=0xd2ad3781a4da482a86b042541d7b37e8

[root@tvm02 ad]# getfattr -d -m . -e hex  d2ad3781-a4da-482a-86b0-42541d7b37e8
# file: d2ad3781-a4da-482a-86b0-42541d7b37e8
trusted.afr.dirty=0x000000000000000000000000
trusted.afr.gv1-test1-client-0=0x000000000000000000000000
trusted.afr.gv1-test1-client-1=0x000000000000000000000000
trusted.afr.gv1-test1-client-2=0x000000000000000000000000
trusted.bit-rot.version=0x03000000000000005a687a2f000856e0
trusted.gfid=0xd2ad3781a4da482a86b042541d7b37e8


##### 恢复后的状态
[root@tvm00 ad]# gluster volume heal gv1-test1 info
Brick 10.200.50.107:/data1/glusterfs_data/gv1-test1
Status: Connected
Number of entries: 0

Brick 10.200.50.108:/data1/glusterfs_data/gv1-test1
Status: Connected
Number of entries: 0

Brick 10.200.50.109:/data1/glusterfs_data/gv1-test1
Status: Connected
Number of entries: 0

[root@tvm00 ad]#

```


##### 因为 glusterfs 创建卷后，默认并未启用 quorum 相关的配置，容易导致脑裂问题。
##### 配置参数示例，特别是 quorum 相关的，用于预防脑裂问题
```bash
gluster volume set gv1-test1 diagnostics.count-fop-hits on
gluster volume set gv1-test1 diagnostics.latency-measurement on
gluster volume set gv1-test1 cluster.server-quorum-type server
gluster volume set gv1-test1 cluster.quorum-type auto
gluster volume set gv1-test1 network.remote-dio enable
gluster volume set gv1-test1 cluster.eager-lock enable
gluster volume set gv1-test1 performance.stat-prefetch off
gluster volume set gv1-test1 performance.io-cache off
gluster volume set gv1-test1 performance.read-ahead off
gluster volume set gv1-test1 performance.quick-read off
```
