# CICD-配置jenkins任务
2018/1/4


### General
- 项目名称
  - pipeline-demo-project
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
    - branch
      - */branch-name
  - 触发 build 方式
    - 手动
  - 输出
    - docker image
    - k8s yaml
    - update etcd key
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
        - 50
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
      - K8S_NAMESPACE
    - Default Value
      - ns-dev
      - ns-test
    - Description
      - k8s的namespace选项
        - ns-dev -> 开发环境
        - ns-test -> 测试环境
  - Boolean Parameter
    - Name
      - FIX_BLOCKED_PKGS
    - Default Value
      - unchecked
    - Description
      - 通过 github 来获取因网络异常无法下载的 go pkg
      - 通常初始化时执行一次即可，默认不选中
  - Boolean Parameter
    - Name
      - FIX_BLOCKED_PKGS
    - Default Value
      - unchecked
    - Description
      - 是否允许构建任务时调用的脚本输出更详细的日志？
      - 默认不选中


### Advanced Project Options
- Display Name
  - [k8s@dev] demo-project [调试中]

### Pipeline
- Definition
  - Pipeline script
    - script
      - （将Jenkinsfile的内容粘贴到这里）
