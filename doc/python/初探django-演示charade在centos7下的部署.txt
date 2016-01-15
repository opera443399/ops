初探django-演示charade在centos7下的部署
=======================================
2016/1/15

####charade 是一个猜单词的小游戏。

prepare
-------
1. pip+django ::

        [root@tvm001 ~]# yum install python-pip
        [root@tvm001 ~]# pip install django
        django 项目用到了 pytz
        [root@tvm001 ~]# pip install pytz

2. 调整 project setting ::

        [root@tvm001 ~]# cd /opt
        直接克隆这个项目 
        [root@tvm001 opt]# git clone https://github.com/opera443399/charade.git
        [root@tvm001 opt]# cd charade/www/

6. 试着运行一下 ::

        django默认是启用了 DEBUG 选项，但 charade 这个项目的代码已经关闭 DEBUG 选项，并设置了 ALLOWED_HOSTS 和 STATIC_ROOT ：
        [root@tvm001 www]# vim www/settings.py
        DEBUG = False
        
        ALLOWED_HOSTS = ['*']
        
        STATIC_ROOT = os.path.join(BASE_DIR,'static')
        
        现在，先临时调整配置：
        [root@tvm001 www]# vim www/settings.py 
        DEBUG = True
        
        运行服务：
        [root@tvm001 www]# python manage.py runserver 0.0.0.0:80
        在浏览器访问，测试确认后台的数据读写无异常后，停止运行，后续将使用uwsgi来管理。
    

7. admin后台 ::

        [root@tvm001 www]# python manage.py createsuperuser
        根据提示创建root密码用于登录后台。
        访问地址：http://you_server_ip/admin/

8. debug ::

        DEBUG 选项处于关闭状态时，则 django 不处理静态文件，此时应该配置nginx或apache来处理静态文件。
    
    
uwsgi+supervisord+nginx
----------------------
1. 安装 ::

        [root@tvm001 www]# yum install nginx python-devel
        [root@tvm001 www]# yum groupinstall "development tools"
        [root@tvm001 www]# pip install supervisor
        [root@tvm001 www]# whereis supervisord
        supervisord: /usr/bin/supervisord /etc/supervisord.conf
        
        [root@tvm001 www]# pip install uwsgi
        [root@tvm001 www]# whereis uwsgi
        uwsgi: /usr/bin/uwsgi    

2. 配置 ::

    1) 收集django项目的static文件：
    
        [root@tvm001 www]# python manage.py collectstatic
    
    2) 使用supervisor来管理uwsgi服务，用uwsgi来运行django：
    
        [root@tvm001 www]# # echo_supervisord_conf > /etc/supervisord.conf \
        && mkdir /etc/supervisor.d \
        && echo -e '[include]\nfiles=/etc/supervisor.d/*.ini' >>/etc/supervisord.conf \
        && grep ^[^\;] /etc/supervisord.conf
        
        [root@tvm001 www]# whereis supervisord
    
    4) 启动 supervisord 服务：
    
        [root@tvm001 www]# /usr/bin/supervisord -c /etc/supervisord.conf
        [root@tvm001 www]# echo '/usr/bin/supervisord -c /etc/supervisord.conf' >>/etc/rc.local
    
    5) 配置uwsgi服务：
    
        [root@tvm001 www]# cat /etc/supervisor.d/uwsgi.ini
        [program:uwsgi]
        command=/usr/bin/uwsgi --socket 127.0.0.1:8090 --chdir /opt/charade/www --module www.wsgi
        
    6）启动 uwsgi 服务：
    
        [root@tvm001 www]# supervisorctl reload
        Restarted supervisord
        [root@tvm001 www]# supervisorctl status
        uwsgi                            RUNNING   pid 5303, uptime 0:00:04
    
        说明：
        uwsgi 使用 --socket 方式，表示：通过socket来访问，因此后续可以用 nginx uwsgi 模块来访问。
        uwsgi 使用 --http 方式，表示：可以直接通过 http访问，因此后续可以用 nginx proxy 来访问。
    
    
    7) 使用nginx来处理静态文件和转发请求到后端的uwsgi服务
    
        a）nginx uwsgi
        [root@tvm001 www]# cat /etc/nginx/conf.d/www.conf 
        server {
            listen 80 default;
            server_name www.test.com;
            charset utf-8;
        
            location /static {
                alias /opt/charade/www/static;
            }
        
            location / {
                uwsgi_pass 127.0.0.1:8090;
                include uwsgi_params;
            }
        }
        
        b）nginx proxy
        [root@tvm001 www]# cat /etc/nginx/conf.d/www.conf 
        upstream backend {
            server 127.0.0.1:8090;
        }
        
        server {
            listen 80 default;
            server_name www.test.com;
            charset utf-8;
            
            location /static {
                alias /opt/charade/www/static;
            }
        
            location / {
                proxy_pass http://backend;
            }
        }
        
        (centos7)
        [root@tvm001 www]# systemctl start nginx.service
        [root@tvm001 www]# systemctl enable nginx.service
