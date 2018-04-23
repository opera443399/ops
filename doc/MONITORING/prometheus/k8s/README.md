# k8s-monitor
2018/4/23

### 在 k8s 中部署 `prometheus`
```bash
kubectl apply -f 01.rbac.yaml --record
kubectl apply -f 02.configmap.yaml --record
kubectl apply -f 03.prom.yaml --record
```

### 在 k8s 外部现有的 `prometheus` 中配置 `federate` 来读取上述 `prometheus` 的 jobs
```yaml
(omitted)
scrape_configs:

  - job_name: 'federate'
    scrape_interval: 15s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~"kubernetes-.*"}'
    static_configs:
      - targets:
        - 'k8s-prom-node-ip:30090'

(omitted)
```


### 在 grafana 中 import 模版
> k8s cluster https://grafana.com/dashboards/315
> k8s app https://grafana.com/dashboards/1471



### FAQ
1. 关于 `blackbox_exporter` 的说明
在 `configmap` 中，使用了 `prometheus` 官方的模版，里边使用了下述内容：
`blackbox-exporter.example.com:9115`

后续将启用这个配置，如果您有兴趣，请参考：https://github.com/prometheus/blackbox_exporter


### ZYXW、参考
1. [prometheus-kubernetes](https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml)
2. [Prometheus监控实践：Kubernetes集群监控](https://www.kubernetes.org.cn/3418.html)
3. [Kubernetes集群监控方案](http://blog.51cto.com/ylw6006/2084403)
