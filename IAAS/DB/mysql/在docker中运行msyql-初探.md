# 在docker中运行msyql-初探
2018/11/23


##### 准备
```bash
~]# docker pull mysql/mysql-server:5.7
~]# mkdir -p /data/server/mysql/3306/{data,log}
~]# chown -R mysql:mysql /data/server/mysql/3306
~]# cd /data/server/mysql/3306

```



##### 这里是一份默认 mysql 配置的示例
```bash
~]# cat <<'_EOF' >my.cnf
[mysqld]
#------------innodb------------
innodb_buffer_pool_size = 4G

#------------replication------------
server-id=101
log_bin=bin.log
sync_binlog=1
gtid_mode=on
enforce_gtid_consistency=1
log_slave_updates
binlog_format=row
relay_log=relay.log
relay_log_recovery=1
binlog_gtid_simple_recovery=1
slave_skip_errors=ddl_exist_errors

#------------basic------------
skip-host-cache
skip-name-resolve
symbolic-links=0
user=mysql
port=3306
character_set_server=utf8mb4
max_connections=800
max_connect_errors=1000

datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
secure-file-priv=/var/lib/mysql-files
pid-file=/var/run/mysqld/mysqld.pid

log-error=/var/log/mysqld.log
log_timestamps=system
slow_query_log=1
slow_query_log_file=/var/log/slow.log
expire_logs_days=90
long_query_time=2
min_examined_row_limit=100

_EOF

```


##### 启动
```bash
docker run -d \
  --name=mysql-3306 \
  -p 3306:3306 \
  -v /etc/localtime:/etc/localtime \
  --mount type=bind,src=/data/server/mysql/3306/my.cnf,dst=/etc/my.cnf \
  --mount type=bind,src=/data/server/mysql/3306/data,dst=/var/lib/mysql \
  --mount type=bind,src=/data/server/mysql/3306/log,dst=/var/log \
  mysql/mysql-server:5.7 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci

docker logs -f mysql-3306

```


##### 初始化后，可查看自动生成的一次性密码
```bash
~]# docker logs mysql-3306 2>&1 | grep GENERATE
[Entrypoint] GENERATED ROOT PASSWORD: Can-Yr(OSyjySBIJAteg4nluvpe

```


##### 修改密码
```bash
~]# docker exec -it mysql-3306 mysql -uroot -p
Enter password:
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';

```


##### 进 shell 操作
```bash
~]# docker exec -it mysql-3306 bash

```



### ZYXW、参考
1. [docker-hub-mysql](https://hub.docker.com/r/mysql/mysql-server/)
2. [Basic Steps for MySQL Server Deployment with Docker](https://dev.mysql.com/doc/refman/8.0/en/docker-mysql-getting-started.html)
3. [More Topics on Deploying MySQL Server with Docker](https://dev.mysql.com/doc/refman/8.0/en/docker-mysql-more-topics.html)
