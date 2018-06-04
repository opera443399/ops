admin
-----
http://0.0.0.0/admin/
root
111111

migrate
-------
python manage.py makemigrations polls
python manage.py sqlmigrate polls 0001
python manage.py migrate

start
-----
python manage.py runserver 0.0.0.0:80
