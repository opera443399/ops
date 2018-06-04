# nginx-proxy配置实例.md
2018/4/17

### exp1
---
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
