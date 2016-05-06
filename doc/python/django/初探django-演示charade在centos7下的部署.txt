初探django-演示charade在centos7下的部署
=======================================
2016/3/3

####charade 是一个猜单词的小游戏。
https://github.com/opera443399/charade

prepare
-------
1. pip+django ::

        主要依赖：
        [root@tvm001 ~]# yum install python-pip
        [root@tvm001 ~]# pip install django
        
        其他依赖：
        django 项目用到了 pytz，需要安装：
        # https://docs.djangoproject.com/es/1.9/topics/i18n/timezones/
        [root@tvm001 ~]# pip install pytz
        
        upload 这个 app 用到了 Pillow，需要安装：
        [root@tvm001 ~]# pip install Pillow
        如果报错类似："ValueError: jpeg is required ...."，则：
        [root@tvm001 ~]# yum install libjpeg-devel
        


2. 调整 project setting ::

        [root@tvm001 ~]# cd /opt
        直接克隆这个项目
        [root@tvm001 opt]# git clone https://github.com/opera443399/charade.git
        [root@tvm001 opt]# cd charade/www/


3. 试着运行一下 ::

        django默认是启用了 DEBUG 选项，但 charade 这个项目的代码已经关闭 DEBUG 选项，并设置了一下内容：
        ALLOWED_HOSTS
        STATIC_URL STATIC_ROOT
        MEDIA_URL MEDIA_ROOT
        
        具体请参考下面的示例：
        [root@tvm001 www]# vim www/settings.py
        DEBUG = False

        ALLOWED_HOSTS = ['*']
        
        # Static files (CSS, JavaScript, Images)
        # https://docs.djangoproject.com/en/1.9/howto/static-files/
        
        STATIC_URL = '/static/'
        STATIC_ROOT = os.path.join(BASE_DIR, 'static')
        
        # Upload files
        # https://docs.djangoproject.com/en/1.9/howto/static-files/#serving-files-uploaded-by-a-user-during-development
        # https://docs.djangoproject.com/en/1.9/ref/templates/builtins/#std:templatetag-get_media_prefix
        MEDIA_URL = '/media/'
        MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
        
        和 MEDIA 相关的调整如下：
        [root@tvm001 www]# vim www/urls.py
        from django.conf import settings
        from django.conf.urls.static import static
        
        urlpatterns = [
            # ... the rest of your URLconf goes here ...
        ] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

        现在，先临时调整配置：
        [root@tvm001 www]# vim www/settings.py
        DEBUG = True

        运行服务：
        [root@tvm001 www]# python manage.py runserver 0.0.0.0:80
        在浏览器访问，测试确认后台的数据读写无异常后，停止运行，后续将使用uwsgi来管理。


4. admin后台 ::

        [root@tvm001 www]# python manage.py createsuperuser
        根据提示创建root密码用于登录后台。
        访问地址：http://you_server_ip/admin/


5. debug ::

        DEBUG 选项处于关闭状态时，则 django 不处理静态文件，此时应该配置nginx或apache来处理静态文件。


6. i18n(国际化和本地化) ::

        增加中间件：locale
        设置可选语言：LANGUAGES
        [root@tvm01 www]# vim www/settings.py
        MIDDLEWARE_CLASSES = [
            （略）
            'django.contrib.sessions.middleware.SessionMiddleware',
            'django.middleware.locale.LocaleMiddleware',
            'django.middleware.common.CommonMiddleware',
            （略）
        ]

        LANGUAGES = [
            ('en', 'English'),
            ('zh-cn', 'zh'),
        ]

        启用 django 自带的语言偏好设置的视图
        [root@tvm01 www]# vim www/urls.py
        urlpatterns = [
            （略）
            url(r'^i18n/', include('django.conf.urls.i18n')),
        ]


        维护翻译文件，在每个 apps 目录下有一个 locale 目录，以 charade 为例：
        创建或更新：
        [root@tvm01 charade]# django-admin makemessages -l zh
        对应的消息文本的路径：locale/zh/LC_MESSAGES/django.po

        编译：
        [root@tvm01 charade]# django-admin compilemessages
        编译后的文件：locale/zh/LC_MESSAGES/django.mo

        最后，重载（reload） web服务即可生效。


7. Email ::

        配置smtp帐号信息，增加如下所示 email 相关的信息
        [root@tvm01 www]# vim www/settings.py
        # email
        EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
        EMAIL_USE_TLS = False
        EMAIL_HOST = 'smtp.xxx.com'
        EMAIL_PORT = 25
        EMAIL_HOST_USER = 'test@xxx.com'
        EMAIL_HOST_PASSWORD = 'TestEmail'
        DEFAULT_FROM_EMAIL = 'TestEmail <test@xxx.com>'

        如果要在 accounts 这个 app 中启用 '注册账户时，发送激活账户的邮件'功能，则：
        编辑 apps.py，调整配置文件如下所示：
        [root@tvm01 www]# vim www/accounts/apps.py
        IS_NEW_USER_NEED_VERIFY_BY_EMAIL = True



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
        user=nobody
        autostart=true
        autorestart=true
        stdout_logfile=/tmp/charade.stdout.log
        stderr_logfile=/tmp/charade.stderr.log

        注：这里配置了 user，对应的，project的目录也应该是这个用户才能对示例中的本地数据库有读写权限。
        [root@tvm001 www]# chown nobody:nobody -R /opt/charade/www

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
            
            location /media {
                alias /opt/charade/www/media;
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
            
            location /media {
                alias /opt/charade/www/media;
            }
            
            location / {
                proxy_pass http://backend;
            }
        }

        (centos7)
        [root@tvm001 www]# systemctl start nginx.service
        [root@tvm001 www]# systemctl enable nginx.service
