# 在docker中运行msyql-初探
2018/11/8


##### 准备
```bash
~]# mkdir -p /data/mysql/3306/{data,log}
~]# docker pull mysql/mysql-server:5.7

```



##### 这里是一份默认 mysql 配置的示例
```bash
~]# cat <<'_EOF' >/data/mysql/3306/my.cnf
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/5.7/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove leading # to turn on a very important data integrity option: logging
# changes to the binary log between backups.
# log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M
skip-host-cache
skip-name-resolve
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
secure-file-priv=/var/lib/mysql-files
user=mysql

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
_EOF

```


##### 启动
```bash
~]# docker run --name=mysql-3306 \
  --mount type=bind,src=/data/mysql/3306/my.cnf,dst=/etc/my.cnf \
  --mount type=bind,src=/data/mysql/3306/data,dst=/var/lib/mysql \
  --mount type=bind,src=/data/mysql/3306/log,dst=/var/log \
  -d mysql/mysql-server:5.7 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci

```


##### 初始化后，可查看自动生成的一次性密码
```bash
~]# docker logs mysql-3306 2>&1 | grep GENERATE
[Entrypoint] GENERATED ROOT PASSWORD: Can-Yr(OSyjySBIJAteg4nluvpe

```


##### 修改密码
```bash
~]# docker exec -it mysql-3306 mysql -uroot -p
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
