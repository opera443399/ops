# zookeeper-初探
2018/11/9

**准备工作**
```bash
[root@zoo3 tmp]# wget http://download.oracle.com/otn-pub/java/jdk/9+181/jdk-9_linux-x64_bin.rpm?AuthParam=1508142788_9ec1d6a7d91a1c07990487ccbdefe36a -O jdk-9_linux-x64_bin.rpm
[root@zoo3 tmp]# wget https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz


[root@zoo3 tmp]# rpm -ivh jdk-9_linux-x64_bin.rpm

```


然后在 /etc/profile 增加：
```bash
[root@zoo3 tmp]# cat <<'_EOF' >>/etc/profile.conf
export JAVA_HOME=/usr/java/default
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin

_EOF
```

在 hosts 增加：
```bash
[root@zoo3 conf]# cat <<'_EOF' >>/etc/hosts
10.200.50.101 zoo1
10.200.50.102 zoo2
10.200.50.103 zoo3
_EOF
```


**配置**
```bash
[root@zoo3 tmp]# tar zxvf zookeeper-3.4.10.tar.gz
[root@zoo3 tmp]# mv zookeeper-3.4.10 /opt/
[root@zoo3 tmp]# ln -s /opt/zookeeper-3.4.10 /opt/zookeeper


[root@zoo3 tmp]# mkdir -p /data/zookeeper/zookeeper/{data,log}
[root@zoo3 tmp]# cd /opt/zookeeper/conf

[root@zoo3 conf]# cat <<'_EOF' >zoo.cfg
tickTime=2000
initLimit=5
syncLimit=2
dataDir=/data/zookeeper/zookeeper/data
dataLogDir=/data/zookeeper/zookeeper/log
clientPort=2181

server.1=zoo1:2888:3888
server.2=zoo2:2888:3888
server.3=zoo3:2888:3888

_EOF
```

**分别在上述3个服务器上执行**
```bash
echo "1" >/data/zookeeper/zookeeper/data/myid
echo "2" >/data/zookeeper/zookeeper/data/myid
echo "3" >/data/zookeeper/zookeeper/data/myid
```


**启动**
```bash
[root@zoo3 conf]# /opt/zookeeper/bin/zkServer.sh start
```

**查看**
```bash
[root@zoo3 conf]# /opt/zookeeper/bin/zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /opt/zookeeper/bin/../conf/zoo.cfg
Mode: leader
```

**测试**
```bash
[root@zoo3 conf]# /opt/zookeeper/bin/zkCli.sh -server 10.200.50.103:2181
[zk: 10.200.50.103:2181(CONNECTED) 0] ls /

[zookeeper]
[zk: 10.200.50.103:2181(CONNECTED) 1] create /zk_test test_data
Created /zk_test
[zk: 10.200.50.103:2181(CONNECTED) 2] ls /
[zookeeper, zk_test]
[zk: 10.200.50.103:2181(CONNECTED) 3] get /zk_test
test_data
cZxid = 0x100000002
ctime = Mon Oct 16 16:57:24 CST 2017
mZxid = 0x100000002
mtime = Mon Oct 16 16:57:24 CST 2017
pZxid = 0x100000002
cversion = 0
dataVersion = 0
aclVersion = 0
ephemeralOwner = 0x0
dataLength = 9
numChildren = 0
[zk: 10.200.50.103:2181(CONNECTED) 4] quit
Quitting...
2017-10-16 16:57:43,437 [myid:] - INFO  [main:ZooKeeper@684] - Session: 0x15f2463ffc20000 closed
2017-10-16 16:57:43,438 [myid:] - INFO  [main-EventThread:ClientCnxn$EventThread@519] - EventThread shut down for session: 0x15f2463ffc20000
[root@zoo3 conf]#
```



### ZYXW、参考
1. [doc](http://zookeeper.apache.org/doc/trunk/zookeeperAdmin.html)
2. [大数据集群环境搭建——ZooKeeper篇](https://segmentfault.com/a/1190000007236556)
