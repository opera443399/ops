# phabricator 初始化
2018/1/19

### 准备域名
http://phab-www.sz.office
http://phab-files.sz.office


### 安装
参考：
https://secure.phabricator.com/book/phabricator/article/installation_guide/
下载安装脚本：
install_rhel-derivs.sh


假设后续操作上在这个目录下执行的：
~]# mkdir -p /data/server/phabricator

##### 安装
~]# sh install_rhel-derivs.sh


##### php
~]# yum install php-opcache
~]# vim /etc/php.ini
post_max_size = 32M
always_populate_raw_post_data = "-1"
date.timezone = "Asia/Shanghai"

###### httpd
~]# cat /etc/httpd/conf.d/phabricator.conf
<Directory "/data/server/phabricator/phabricator/webroot">
  Require all granted
</Directory>

<VirtualHost *>
  # Change this to the domain which points to your host.
  ServerName phab-www.sz.office
  ServerAlias phab-files.sz.office

  # Change this to the path where you put 'phabricator' when you checked it
  # out from GitHub when following the Installation Guide.
  #
  # Make sure you include "/webroot" at the end!
  DocumentRoot /data/server/phabricator/phabricator/webroot

  RewriteEngine on
  RewriteRule ^(.*)$          /index.php?__path__=$1  [B,L,QSA]
</VirtualHost>


~]# systemctl enable httpd && systemctl start httpd


### DB
参考：https://www.cnblogs.com/river2005/p/6813618.html
~]# systemctl enable mariadb && systemctl start mariadb
~]# mysql_secure_installation
root@127.0.0.1
xxxxxx


##### 字符集调整
# 先查看
MariaDB [(none)]> show variables like "%character%";show variables like "%collation%";
# 增加配置
~]# vim /etc/my.cnf.d/mariadb-server.cnf
[mysqld]
init_connect='SET collation_connection = utf8_unicode_ci'
init_connect='SET NAMES utf8'
character-set-server=utf8
collation-server=utf8_unicode_ci
skip-character-set-client-handshake

~]# vim /etc/my.cnf.d/client.cnf
[client]
default-character-set=utf8

~]# vim /etc/my.cnf.d/mysql-clients.cnf
[mysql]
default-character-set=utf8

~]# systemctl restart mariadb


##### 配置mysql
./phabricator/bin/config set mysql.host 127.0.0.1
./phabricator/bin/config set mysql.user root
./phabricator/bin/config set mysql.pass xxxxxx

./phabricator/bin/storage upgrade




### 登陆 phabricator 的 web 页面后，根据提示来完成剩余的安装设置
##### 配置域名
./phabricator/bin/config set phabricator.base-uri 'http://phab-www.sz.office/'
./phabricator/bin/config set security.alternate-file-domain 'http://phab-files.sz.office/'


##### user reset
./phabricator/bin/auth recover root

##### 用户
用户名+密码+email域限制

### 文件存储路径
./phabricator/bin/config set storage.local-disk.path '/data/server/phabricator/files'
./phabricator/bin/config set repository.default-local-path "/data/server/phabricator/repo"


### SMTP
./phabricator/bin/config set phpmailer.smtp-host ""
./phabricator/bin/config set phpmailer.smtp-user ""
./phabricator/bin/config set phpmailer.smtp-password ""
