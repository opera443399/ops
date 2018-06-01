初探go-dep使用小结
2018/6/1


### 前言
##### 用来干什么
dep 是用来解决 go 的依赖问题的

##### 准备工作
```bash
~]# go get -u github.com/golang/dep/cmd/dep
~]# dep help
Dep is a tool for managing dependencies for Go projects

Usage: "dep [command]"

Commands:

  init     Set up a new Go project, or migrate an existing one
  status   Report the status of the project's dependencies
  ensure   Ensure a dependency is safely vendored in the project
  prune    Pruning is now performed automatically by dep ensure.
  version  Show the dep version information

Examples:
  dep init                               set up a new project
  dep ensure                             install the project's dependencies
  dep ensure -update                     update the locked versions of all dependencies
  dep ensure -add github.com/pkg/errors  add a dependency to the project

Use "dep help [command]" for more information about a command.
```

### 操作示例
##### 初始化
在代码中 import 了库后，在代码目录先初始化：
```bash
~]# dep init -v

~]# ls
app.go  Gopkg.lock  Gopkg.toml  vendor
```

##### 指定依赖的版本
如果有需要指定版本的，则修改 Gopkg.toml
然后执行：
```bash
~]# dep ensure -update -v
```


关于约束指定的版本，以 `Gopkg.toml` 的内容示例
```yaml
[[constraint]]
  name = "google.golang.org/grpc"
  version = "=v1.3.0"
```
上述表示使用 1.3.0 这个版本，当然，还有以下表示方法：

"1.3.0"        约束使用 1.3.0 - 2.0.0 之间的最新版
"<=1.3.0"       约束使用最高版本为 1.3.0


详细的解释请参考文档：
https://github.com/golang/dep/blob/master/README.md


注意细节：
https://github.com/golang/dep/issues/1321


如果有依赖关联了，例如：
github.com/coreos/etcd
使用了 grpc 的新版本，则上述指定的 grpc 的依赖将失效，从而拉取到最新的版本 1.7.3（不符合预期，本以为是 1.3.0 这个版本）




##### 查看当前版本
```bash
~]# dep status
PROJECT                                           CONSTRAINT    VERSION          REVISION  LATEST   PKGS USED
github.com/coreos/etcd                              3.2.10       v3.2.10         6f48bda   6f48bda  6
google.golang.org/grpc                              1.3.0       v1.7.3           401e0e0   d2e1b51  17
k8s.io/kubernetes                                   1.8.3       v1.8.3           f0efb3c   f0efb3c  7
```

##### 约定版本
显然，，约束的是 `1.3.0` 然而实际上却使用了 `1.7.3`
此时，我还是想强制使用该版本，怎么办？（但要注意，因为有其他的组件，例如 etcd 也使用了该库，强制覆盖将导致异常，因而，要根据实际情况来判断）
使用 `override` 来覆盖
```yaml
[[override]]
  name = "google.golang.org/grpc"
  version = "=v1.3.0"
```

##### 更新
```bash
~]# dep ensure -update -v

~]# dep status
PROJECT                                           CONSTRAINT        VERSION      REVISION  LATEST   PKGS USED
github.com/coreos/etcd                              3.2.10       v3.2.10         6f48bda   6f48bda  6
google.golang.org/grpc                              * (override)    v1.3.0       d2e1b51   401e0e0  14
k8s.io/kubernetes                                   1.8.3           v1.8.3       f0efb3c   f0efb3c  7
```




### ZYXW、参考
1. [初窥dep](http://tonybai.com/2017/06/08/first-glimpse-of-dep/)
