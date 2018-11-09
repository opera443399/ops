# zookeeper-在docker中运行
2018/11/9


### zk
---
**zk 集群对应的 docker stack 配置**
```yaml
~]# cat stack.yml
version: "3.3"

volumes:
  zkdata:
  zkdatalog:

networks:
  net:
    driver: overlay
    attachable: true

services:
  zoo1:
    image: zookeeper
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
      resources:
        limits:
          cpus: "0.5"
          memory: 512M
    networks:
      - net
    volumes:
      - "zkdata:/data"
      - "zkdatalog:/datalog"
    hostname: zoo1
    ports:
      - 2181:2181
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=0.0.0.0:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888
      ZOO_MAX_CLIENT_CNXNS: 1000

  zoo2:
    image: zookeeper
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
      resources:
        limits:
          cpus: "0.5"
          memory: 512M
    networks:
      - net
    volumes:
      - "zkdata:/data"
      - "zkdatalog:/datalog"
    hostname: zoo2
    ports:
      - 2182:2181
    environment:
      ZOO_MY_ID: 2
      ZOO_SERVERS: server.1=zoo1:2888:3888 server.2=0.0.0.0:2888:3888 server.3=zoo3:2888:3888
      ZOO_MAX_CLIENT_CNXNS: 1000

  zoo3:
    image: zookeeper
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
      resources:
        limits:
          cpus: "0.5"
          memory: 512M
    networks:
      - net
    volumes:
      - "zkdata:/data"
      - "zkdatalog:/datalog"
    hostname: zoo3
    ports:
      - 2183:2181
    environment:
      ZOO_MY_ID: 3
      ZOO_SERVERS: server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=0.0.0.0:2888:3888
      ZOO_MAX_CLIENT_CNXNS: 1000

```

**启动集群**
```bash
~]# cat start.sh
docker stack deploy -c stack.yml zk
sleep 2s
docker stack ps zk

```


**测试**
```bash
~]# docker run -it --rm --network zk_net zookeeper zkCli.sh -server zoo1
[zk: zoo1(CONNECTED) 0] ls /

```



### zkui
---
**zkui的配置示例**
```bash
~]# cat zkui.cfg
#Server Port
serverPort=9090
#Comma seperated list of all the zookeeper servers
zkServer=zoo1:2181,zoo2:2181,zoo3:2181
#Http path of the repository. Ignore if you dont intent to upload files from repository.
scmRepo=http://myserver.com/@rev1=
#Path appended to the repo url. Ignore if you dont intent to upload files from repository.
scmRepoPath=//appconfig.txt
#if set to true then userSet is used for authentication, else ldap authentication is used.
ldapAuth=false
ldapDomain=mycompany,mydomain
#ldap authentication url. Ignore if using file based authentication.
ldapUrl=ldap://<ldap_host>:<ldap_port>/dc=mycom,dc=com
#Specific roles for ldap authenticated users. Ignore if using file based authentication.
ldapRoleSet={"users": [{ "username":"domain\\user1" , "role": "ADMIN" }]}
userSet = {"users": [{ "username":"admin" , "password":"manager","role": "ADMIN" },{ "username":"appconfig" , "password":"appconfig","role": "USER" }]}
#Set to prod in production and dev in local. Setting to dev will clear history each time.
env=prod
jdbcClass=org.h2.Driver
jdbcUrl=jdbc:h2:zkui
jdbcUser=root
jdbcPwd=manager
#If you want to use mysql db to store history then comment the h2 db section.
#jdbcClass=com.mysql.jdbc.Driver
#jdbcUrl=jdbc:mysql://localhost:3306/zkui
#jdbcUser=root
#jdbcPwd=manager
loginMessage=Please login using admin/manager or appconfig/appconfig.
#session timeout 5 mins/300 secs.
sessionTimeout=300
#Default 5 seconds to keep short lived zk sessions. If you have large data then the read will take more than 30 seconds so increase this accordingly.
#A bigger zkSessionTimeout means the connection will be held longer and resource consumption will be high.
zkSessionTimeout=5
#Block PWD exposure over rest call.
blockPwdOverRest=false
#ignore rest of the props below if https=false.
https=false
keystoreFile=/home/user/keystore.jks
keystorePwd=password
keystoreManagerPwd=password
# The default ACL to use for all creation of nodes. If left blank, then all nodes will be universally accessible
# Permissions are based on single character flags: c (Create), r (read), w (write), d (delete), a (admin), * (all)
# For example defaultAcl={"acls": [{"scheme":"ip", "id":"192.168.1.192", "perms":"*"}, {"scheme":"ip", id":"192.168.1.0/24", "perms":"r"}]
defaultAcl=
# Set X-Forwarded-For to true if zkui is behind a proxy
X-Forwarded-For=false

```


**运行**
```bash
~]# cat ui.sh
docker rm -f zkui
docker run \
  --name zkui \
  -d \
  --network zk_net \
  --restart=always \
  -p 9090:9090 \
  -v "$(pwd)/zkui.cfg":/opt/zkui/config.cfg \
  opera443399/zkui:2

```


### ZYXW、参考
1. [docker-hub-zk](https://hub.docker.com/_/zookeeper/)
2. [zkui](https://github.com/opera443399/zkui)
