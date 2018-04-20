# CICD-配置jenkins任务
2018/4/19


### General
- 项目名称
  - pipeline-demoproject
- 描述
  - 负责人
    - xxx@xxx.com
  - 状态
    - 调试中
  - worker 节点的约束条件
    - label=pipeline_only
  - git
    - location
      - xxx.git
  - 触发 build 方式
    - 手动
  - 输出
    - docker image
    - k8s yaml
    - update etcd key
- Do not allow concurrent builds
  - 勾选
- 丢弃旧的构建
  - Strategy
    - Log Rotation
      - 保持构建的天数
        - 14
- 参数化构建过程
  - Extended Choice Parameter
    - Name
      - SVC_NAMES
    - Description
      - 【请选择】上面指定的微服务名称（当前有xx个）
    - Basic Parameter Types
      - Parameter Type
        - Check Boxes
      - Number of Visible Items
        - 20
      - Delimiter
        - ,
    - Choose Source for Value
      - Value
        - Value
          - s1,s2,s3,s4,s5,s6
  - String Parameter
    - Name
      - SVC_VERSION
    - Default Value
      - EMPTY
    - Description
      - 指定版本后，将作为 docker image 的 tag 值，默认将提取 "git rev" 来作为版本号
  - Choice Parameter
    - Name
      - GIT_BRANCH_NAME
    - Default Value
      - refs/heads/master
      - refs/heads/feature1
      - refs/tags/release1
    - Description
      - 请选择 git 分支
  - Choice Parameter
    - Name
      - K8S_NAMESPACE
    - Default Value
      - ns-demo-dev
      - ns-demo-test
    - Description
      - 请选择部署至 k8s 的哪一个 namespace 中
        - ns-demo-dev -> 开发环境
        - ns-demo-test -> 测试环境
  - Boolean Parameter
    - Name
      - LOG_LEVEL_DEBUG
    - Default Value
      - unchecked
    - Description
      - 是否允许构建任务时调用的脚本输出更详细的日志？
  - Boolean Parameter
    - Name
      - NEED_UNDO
    - Default Value
      - unchecked
    - Description
      - 请确认是否需要执行回滚操作？



### Advanced Project Options
- Display Name
  - [开发][k8s] demoproject

### Pipeline
- Definition
  - Pipeline script
    - script
      - （将Jenkinsfile的内容粘贴到这里）
