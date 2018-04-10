# nginx日志格式实例
2018/4/10


##### 日志格式1（常规）
```nginx
log_format  log_main '$remote_addr $server_addr $remote_user [$time_local] $host '
            '"$request" $status $body_bytes_sent $request_time "$upstream_addr" "$upstream_response_time" '
            '"$http_referer" "$http_user_agent" "$http_x_forwarded_for"';
```

> 记录内容（分行显示，实际上是1行）
```nginx
201.33.44.55 192.168.1.100 - [10/Apr/2018:18:30:20 +0800] demo.test.com
"POST /d1/f2/c3/check HTTP/1.1" 200 39 0.099 "10.250.200.33:11111" "0.099"
"http://j.test.com/" "Safari/537.36" "103.4.5.6"
```

##### 日志格式2（获取 req+resp 的内容，需了解 lua 相关的知识点）
```nginx
log_format log_with_req_resp '$remote_addr - $remote_user [$time_local] '
            '"$request" $status $body_bytes_sent $request_time "$upstream_addr" "$upstream_response_time" '
            '"$http_referer" req_body:"$request_body" resp_body:"$resp_body"';
```

> 记录内容（分行显示，实际上是1行）
```nginx
201.33.44.55 - - [10/Apr/2018:18:30:20 +0800]
"GET / HTTP/1.1" 502 269 0.000 "10.250.200.33:11111" "0.000"
"http://j.test.com/" req_body:"-" resp_body:"<!DOCTYPE HTML PUBLIC \x22-//IETF//DTD HTML 2.0//EN\x22>\x0D\x0A<html>\x0D\x0A<head><title>502 Bad Gateway</title></head>\x0D\x0A<body bgcolor=\x22white\x22>\x0D\x0A<h1>502 Bad Gateway</h1>\x0D\x0A<p>The proxy server received an invalid response from an upstream server.<hr/>Powered by Tengine</body>\x0D\x0A</html>\x0D\x0A"
```

> nginx对应的配置实例
```bash
]# cat demo.test.com.conf
    upstream backend {
        ip_hash;
        server 10.250.200.33:11111 weight=100 max_fails=3 fail_timeout=20s;
        server 10.250.200.34:11111 weight=100 max_fails=3 fail_timeout=20s;
    }

    server {
        server_name demo.test.com.com;
        listen 80;

        location /{
            lua_need_request_body on;

            set $resp_body "";
            body_filter_by_lua '
                local resp_body = string.sub(ngx.arg[1], 1, 1000)
                ngx.ctx.buffered = (ngx.ctx.buffered or "") .. resp_body
                if ngx.arg[2] then
                    ngx.var.resp_body = ngx.ctx.buffered
                end
            ';

            access_log logs/access_test.log  log_with_req_resp;
            error_log  logs/error_test.log crit;

            proxy_redirect off;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_pass http://backend;
            proxy_set_header X-Forwarded-For $http_x_forwarded_for;
        }

}
```


ZYXW、参考
1、[nginx 获取 post body值](https://blog.csdn.net/yangguanghaozi/article/details/52367118)
