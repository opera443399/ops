# ci目录结构示例
2018/4/20

### 持续集成时工作目录示例结构如下：

```bash
/data/server/jenkins_node_workspace/cicd
├── bin
│   ├── backup.sh
│   ├── cleanup.sh
├── docker.images                   # 基础镜像
│   ├── ns-base                     # 命名空间
│   │   └── image-base-demo         # 镜像名称
│   │       ├── build.sh
│   │       └── Dockerfile
│   └── README.md
├── demo1-not-in-k8s                # 构建不运行在 k8s 上的微服务
│   ├── ci.sh                       # 对应的 ci 脚本
│   └── tpl.docker.d                # 每个微服务对应的 Dockerfile
│       ├── s1
│       │   └── Dockerfile
│       ├── s2
│       │   └── Dockerfile
│       ├── s3
│       │   └── Dockerfile
│       └── s4
│           └── Dockerfile
└── demo2-in-k8s                    # 构建运行在 k8s 上的微服务
    ├── ci.sh                       # 对应的 ci 脚本
    ├── k8s.yaml.d                  # k8s 配置，用于首次部署微服务，可同步到 k8s master 上执行
    │   ├── ns-demo2-dev            # 命名空间（开发环境）
    │   │   ├── s1.yaml             # 微服务的 k8s deploy/svc 的配置文件（根据模版自动生成）
    │   │   ├── s2.yaml
    │   │   ├── s3.yaml
    │   │   ├── s4.yaml
    │   │   └── s5.yaml
    │   └── ns-demo2-test           # 另一个命名空间（测试环境）
    │       ├── s1.yaml
    │       ├── s2.yaml
    │       ├── s3.yaml
    │       ├── s4.yaml
    │       └── s5.yaml
    └── tpl.docker.d                        # 每个微服务的模版
        ├── s1                              # 微服务名称
        │   ├── Dockerfile                  # 微服务对应的 Dockerfile
        │   ├── k8s.ns-demo2-dev.yaml       # 指定命名空间下的 k8s deploy/svc 的配置文件模版
        │   └── k8s.ns-demo2-test.yaml      # 指定命名空间下的 k8s deploy/svc 的配置文件模版
        ├── s2
        │   ├── Dockerfile
        │   ├── k8s.ns-demo2-dev.yaml
        │   └── k8s.ns-demo2-test.yaml
        ├── s3
        │   ├── Dockerfile
        │   ├── k8s.ns-demo2-dev.yaml
        │   └── k8s.ns-demo2-test.yaml
        ├── s4
        │   ├── Dockerfile
        │   ├── k8s.ns-demo2-dev.yaml
        │   └── k8s.ns-demo2-test.yaml
        └── s5
            ├── Dockerfile
            ├── k8s.ns-demo2-dev.yaml
            └── k8s.ns-demo2-test.yaml

```
