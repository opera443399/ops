# mysql5.7导出用户信息
2018/11/8

### 脚本
```bash
# cat u.sh
pwd=password

mysql -B -u'root' -p${pwd} -N  -P3306  $@ -e "SELECT CONCAT('SHOW CREATE USER ''', user, '''@''', host, ''';') AS query FROM mysql.user" | \
mysql -u'root' -p${pwd} -P3306 -f  $@ | \
sed 's#$#;#g;s/^\(CREATE USER for .*\)/-- \1 /;/--/{x;p;x;}'

mysql -B -u'root' -p${pwd} -N  -P3306  $@ -e "SELECT CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, ''';') AS query FROM mysql.user" | \
mysql -u'root' -p${pwd} -P3306 -f  $@ | \
sed 's/\(GRANT .*\)/\1;/;s/^\(Grants for .*\)/-- \1 /;/--/{x;p;x;}'


# sh u.sh >u.sql

```



### ZYXW、参考
1. [mysql 5.6 5.7 导出用户授权信息](https://blog.csdn.net/u011665746/article/details/79067656)
