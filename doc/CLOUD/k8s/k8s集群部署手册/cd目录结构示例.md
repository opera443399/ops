# cd目录结构示例
2018/1/22

```bash
/data/server/k8s-deploy
├── bin
│   ├── backup.sh
│   ├── confd_ctl.sh
│   └── confd_reload_cmd.sh
├── k8s.yaml.d                                      # 微服务的配置文件根目录
│   ├── public                                      # 公共资源
│   │   ├── ns                                      # 命名空间
│   │   │   ├── ns-demo2-dev.yaml                     # 新建一个命名空间 ns-demo2-dev
│   │   │   └── ns-demo2-test.yaml
│   │   ├── secrets                                 # secrets
│   │   │   ├── hub-demo2-dev.yaml                    # 用于私有镜像的 secrets
│   │   │   └── hub-demo2-test.yaml
│   │   └── volume                                  # 存储
│   │       └── glusterfs                             # glusterfs 存储
│   │           ├── 10.endpoints                        # 根据 ns 来分类定义 ep
│   │           │   └── glusterfs-r3
│   │           │       ├── ns-default.yaml
│   │           │       ├── ns-demo2-dev.yaml
│   │           │       └── ns-demo2-test.yaml
│   │           ├── 20.pv                               # 根据 ns 来分类定义 pv
│   │           │   └── glusterfs-r3
│   │           │       ├── gv1-default.yaml
│   │           │       ├── gv1-ns-demo2-dev.yaml
│   │           │       └── gv1-ns-demo2-test.yaml
│   │           ├── 30.pvc                              # 根据 ns 来分类定义 pvc
│   │           │   └── glusterfs-r3
│   │           │       ├── gv1-default.yaml
│   │           │       ├── gv1-ns-demo2-dev.yaml
│   │           │       └── gv1-ns-demo2-test.yaml
│   │           ├── bin                                 # 根据 ns 来分类创建 glusterfs 卷
│   │           │   ├── create-default.sh
│   │           │   ├── create-gv1-ns-demo2-dev.sh
│   │           │   └── create-gv1-ns-demo2-test.sh
│   │           └── deploy_test                         # 测试专用微服务，验证新创建的 volume 是否符合预期
│   │               ├── gv1-default-t1.yaml
│   │               ├── gv1-ns-demo2-dev-t1.yaml
│   │               └── gv1-ns-demo2-test-t1.yaml
│   └── demo2-in-k8s                                # 微服务 demo2-in-k8s 的定义，初次部署时用，来源于 CI 的输出
│       └── k8s.yaml.d
│           ├── ns-demo2-dev
│           │   ├── s1.yaml
│           │   ├── s2.yaml
│           │   ├── s3.yaml
│           │   ├── s4.yaml
│           │   └── s5.yaml
│           └── ns-demo2-test
│               ├── s1.yaml
│               ├── s2.yaml
│               ├── s3.yaml
│               ├── s4.yaml
│               └── s5.yaml
├── logs                            # confd 的 reload 日志
│   └── xxx.log
└── reload                          # confd 使用的临时脚本
    └── auto.create.cmd


```
