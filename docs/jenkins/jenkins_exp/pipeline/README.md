# CI目录结构示例
2018/7/10


*CI的工作目录结构示例*

```bash
/data/server/jenkins_worker/cicd
├── bin
│   └── backup.sh
├── docker.images                   # 这里归类为基础镜像
│   ├── ns-demo                     # docker image registry 中的一个 namespace
│   │   └── image-base-demo         # 镜像名称
│   │       ├── build.sh            # 构建脚本
│   │       └── Dockerfile          # 预定义的配置
│   └── README.md
├── demo1-not-in-k8s                # 项目名称
│   ├── ci.sh                       # 项目对应的 ci 脚本
│   └── tpl.docker.d                # 模版
│       ├── s1                      # 每个微服务对应的模版目录
│       │   └── Dockerfile
│       └── s2
│           └── Dockerfile
└── demo2-in-k8s                    # 项目名称
    ├── ci.sh                       # 项目对应的 ci 脚本
    ├── k8s.yaml.d                  # 项目对应的 k8s yaml 目录
    │   ├── ns-demo1-dev            # 一个 k8s 的 namespace （dev）
    │   │   ├── s1.yaml             # ci 脚本执行后根据模版自动生成的 k8s yaml 文件
    │   │   └── s2.yaml
    │   └── ns-demo2-test           # 另一个 k8s 的 namespace （test）
    │       ├── s1.yaml
    │       └── s2.yaml
    └── tpl.docker.d                        # 模版
        ├── s1                              # 每个微服务对应的模版目录
        │   ├── Dockerfile
        │   ├── k8s.ns-demo1-dev.yaml       # 一个 namespace 下的 k8s yaml 模版
        │   └── k8s.ns-demo1-test.yaml      # 另一个 namespace 下的 k8s yaml 模版
        └── s2
            ├── Dockerfile
            ├── k8s.ns-demo2-dev.yaml
            └── k8s.ns-demo2-test.yaml

```
