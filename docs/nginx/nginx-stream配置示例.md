# nginx-stream配置示例
2018/8/21

nginx 新版本支持 stream 来作为 tcp/udp 的代理

### nginx 配置
```bash
~]# vim /etc/nginx/nginx.conf
(omitted)
stream {
    log_format proxy '$remote_addr [$time_local] '
                     '$protocol $status $bytes_sent $bytes_received '
                     '$session_time "$upstream_addr" '
                     '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';
    access_log /var/log/nginx/stream.access.log proxy;
    include /etc/nginx/stream.conf.d/*.conf;
}
(omitted)

```


### vhost 示例
```bash
~]# cat /etc/nginx/conf.d/k8s-apiserver-vip.demo.com.conf
#tcp: kubernetes.default.svc.cluster.local
upstream k8s-apiserver-vip {
    server 10.50.200.101:6443 weight=5 max_fails=3 fail_timeout=30s;
    server 10.50.200.102:6443 weight=5 max_fails=3 fail_timeout=30s;
    server 10.50.200.103:6443 weight=5 max_fails=3 fail_timeout=30s;
}

server {
    listen 6443;
    proxy_pass k8s-apiserver-vip;
    proxy_connect_timeout 1s;
    proxy_timeout 3s;
    access_log /var/log/nginx/k8s-apiserver-vip.demo.com.log proxy;
}

```
