run
---
python manage.py runserver 0.0.0.0:80

admin
-----
http://0.0.0.0/admin/
root
111111

debug
-----
www/setting.py: DEBUG=True
如果：DEBUG=False，则django不处理静态文件，此时应该配置nginx或apache来处理静态文件
