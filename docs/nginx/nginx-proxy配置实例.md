# nginx-proxy配置实例.md
2018/8/2

### exp1
---
```
upstream backend{
    server 192.168.1.244.8080 weight=10;
    server 192.168.1.245.8080 weight=10;
    server 192.168.1.246.8080 weight=10;
    check interval=3000 rise=2 fall=5 timeout=1000 type=http;
    check_http_send "HEAD / HTTP/1.1\r\nConnection: keep-alive\r\n\r\n";
    check_http_expect_alive http_2xx http_3xx http_4xx;
}


server {
    server_name demo.test.com;
      location ~ / {
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_pass http://backend;
        proxy_set_header X-Forwarded-For $http_x_forwarded_for;
      }
}
```


### exp2: proxy_pass http://backend; vs proxy_pass http://backend/;
---
```
upstream backend {
    server 10.6.27.124:9000 weight=10 max_fails=3  fail_timeout=20s;
    keepalive 400;
}

server {
    listen 80;
    server_name x.test.com;
    add_header 'Access-Control-Allow-Origin' *;
    add_header 'Access-Control-Allow-Credentials' 'true';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTION, HEAD';

    location / {
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_pass http://backend;
        proxy_set_header X-Forwarded-For $http_x_forwarded_for;
    }

    location /ui/ {
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_pass http://backend/;
        proxy_set_header X-Forwarded-For $http_x_forwarded_for;
    }
}
```
