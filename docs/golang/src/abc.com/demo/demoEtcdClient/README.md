# read data from k8s/etcd
# depends on k8s related pkgs around version v1.8


solve depends:
```bash
dep ensure -v
```


run:
```bash
]# go run app.go -h
Usage of /tmp/go-build370598848/command-line-arguments/_obj/exe/app:
  -alsologtostderr
    	log to standard error as well as files
  -endpoint string
    	Etcd endpoint. (default "http://127.0.0.1:2379")
  -log_backtrace_at value
    	when logging hits line file:N, emit a stack trace
  -log_dir string
    	If non-empty, write log files in this directory
  -logtostderr
    	log to standard error instead of files
  -prefix string
    	Etcd prefix (default "/registry/pods/default")
  -stderrthreshold value
    	logs at or above this threshold go to stderr
  -v value
    	log level for V logs
  -vmodule value
    	comma-separated list of pattern=N settings for file-filtered logging
exit status 2

```
