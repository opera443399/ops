=============================
test-django: charade
2016/1/11
=============================

run
---
运行::

  python manage.py runserver 0.0.0.0:80


admin
-----
后台 ::

  http://0.0.0.0/admin/
  root
  111111  


debug
-----
默认安装django后 ::

  www/setting.py: 
  DEBUG=True

如果 ::

  DEBUG=False，则django不处理静态文件，此时应该配置nginx或apache来处理静态文件。


uwsgi+supervisord+nginx
----------------------
一、安装 ::

[root@tvm01 ~]# yum install nginx
[root@tvm01 ~]# pip2.7 install uwsgi

二、配置 ::

    1、关闭django项目的 DEBUG 选项，并设置 ALLOWED_HOSTS 和 STATIC_ROOT ：
    [root@tvm01 ~]# cd /opt/test-django/www
    [root@tvm01 www]# vim www/settings.py
    DEBUG = False
    
    ALLOWED_HOSTS = ['*']
    
    STATIC_ROOT = os.path.join(BASE_DIR,'static')
    
    2、收集django项目的static文件：
    [root@tvm01 www]# python manage.py collectstatic
    
    3、使用uwsgi来运行django服务：
    [root@tvm01 www]# /usr/local/bin/uwsgi --http 127.0.0.1:8090 --chdir /opt/test-django/www --module www.wsgi >/var/log/nginx/uwsgi.log 2>&1 & 
    
    4、使用supervisor来管理uwsgi服务：
    [root@tvm01 www]# pip2.7 install supervisor
    [root@tvm01 www]# echo_supervisord_conf > /etc/supervisord.conf \
    && mkdir /etc/supervisor.d \
    && /usr/bin/echo_supervisord_conf >/etc/supervisord.conf  \
    && echo -e '[include]\nfiles=/etc/supervisor.d/*.ini' >>/etc/supervisord.conf \
    && grep ^[^\;] /etc/supervisord.conf
    
    [root@tvm01 www]# whereis supervisord
    supervisord: /etc/supervisord.conf /usr/local/bin/supervisord
    
    启动 supervisord 服务：
    [root@tvm01 www]# /usr/local/bin/supervisord -c /etc/supervisord.conf
    [root@tvm01 www]# echo '/usr/local/bin/supervisord -c /etc/supervisord.conf' >>/etc/rc.local
    
    5、配置uwsgi服务
    [root@tvm01 www]# cd /etc/supervisor.d
    [root@tvm01 www]# cat uwsgi.ini 
    [program:uwsgi]
    command=/usr/local/bin/uwsgi --socket 127.0.0.1:8090 --chdir /opt/test-django/www --module www.wsgi
    #command=/usr/local/bin/uwsgi --http 127.0.0.1:8090 --chdir /opt/test-django/www --module www.wsgi
    
    启动 uwsgi 服务：
    [root@tvm01 www]# supervisorctl reload
    
    说明：
    uwsgi 使用 --socket 方式，表示：通过socket来访问，因此后续可以用 nginx uwsgi 模块来访问。
    uwsgi 使用 --http 方式，表示：可以直接通过 http访问，因此后续可以用 nginx proxy 来访问。
    
    
    6、使用nginx来处理静态文件和转发请求到后端的uwsgi服务
    1）nginx uwsgi
    [root@tvm01 www]# cat /etc/nginx/conf.d/www.conf 
    server {
        listen 80 default;
        server_name www.test.com;
        charset utf-8;
    
        location /static {
            alias /opt/test-django/www/static;
        }
    
        location / {
            uwsgi_pass 127.0.0.1:8090;
            include uwsgi_params;
        }
    }
    
    2）nginx proxy
    [root@tvm01 www]# cat /etc/nginx/conf.d/www.conf 
    upstream backend {
        server 127.0.0.1:8090;
    }
    
    server {
        listen 80 default;
        server_name www.test.com;
        charset utf-8;
        
        location /static {
            alias /opt/test-django/www/static;
        }
    
        location / {
            proxy_pass http://backend;
        }
    }
    [root@tvm01 www]# service nginx start
