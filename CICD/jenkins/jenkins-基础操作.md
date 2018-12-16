# jenkins-基础操作
2018/11/12

### 一、常规部署方法

##### 准备 jdk
```
推荐使用 oracle jdk 而不是 centos 的yum源自带的 openjdk
默认由于版权问题，centos 默认的yum源未加入 oracle jdk 的包，默认将安装开源版本的oepnjdk
两者的名称差异是这样的：

| 类型 | 版本 |
| --- | --- |
| oracle jdk | jdk-8u102-linux-x64 |
| openjdk | java-1.8.0-openjdk |

请根据需要去 oracle java 网站自行下载 jdk 的 rpm 包来安装（下述链接可能会失效）
```

> 实例
```bash
~]# wget -O jdk-10_linux-x64_bin.rpm http://download.oracle.com/otn-pub/java/jdk/10+46/76eac37278c24557a3c4199677f19b62/jdk-10_linux-x64_bin.rpm?AuthParam=1521624974_b41b4d1af2efcf405abd3aa0a2829fa2

~]# yum localinstall jdk-10_linux-x64_bin.rpm
```

安装 jdk 后，配置一下环境变量：
```bash
~]# cat <<'_EOF' >>/etc/profile.conf
export JAVA_HOME=/usr/java/default
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin

_EOF
```

##### 安装 jenkins 服务的几种姿势
1. yum源安装（推荐）
```bash
~]# wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
~]# rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

~]# yum install jenkins

##### 启动服务
~]# systemctl enable jenkins
~]# systemctl start jenkins
##### (防火墙配置略过)

```

2. 直接下载rpm包来安装
```bash
~]# wget http://pkg.jenkins-ci.org/redhat-stable/jenkins-2.7.4-1.1.noarch.rpm
~]# yum localinstall jenkins-2.7.4-1.1.noarch.rpm
```

3. 直接下载指定的war包来使用
```bash
~]# mkdir -p /opt/jenkins/logs
~]# wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war -O /opt/jenkins/jenkins.war
~]# nohup java -jar /opt/jenkins/jenkins.war >/opt/jenkins/logs/$(date +%F).log 2>&1 &
```

### 二、使用 docker 部署 LTS 的版本
```bash
mkdir -p /data/server/jenkins/data

docker run \
  --name jenkinsci \
  --restart=always \
  -d \
  -u root \
  -p 8080:8080 \
  -v /data/server/jenkins/data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkinsci/jenkins:lts-alpine

```


### 三、服务配置实例
##### 访问
http://ip_of_jenkins:8080/

##### 初始化
- 安装插件
- 帐号、邮件等系统设置
- 创建项目


访问后，根据引导，将安装插件，但jenkins默认会去探测google能否访问，这个，，在国内会困住一批人，解决办法：
请自行搜索关键词：“jenkins connectionCheckUrl”，了解解决办法。
请根据需要安装插件，插件安装报错时，多半是有依赖关系，缺少哪个插件安装即可。

##### 注意事项
- 权限
例如，使用docker服务时，jenkins 用户要加入 docker 组
```bash
usermod -a -G docker jenkins
systemctl restart jenkins
```

- 获取jenkins相关的几个key用于远程调用（注，新版本的jenkins的默认安全设置，导致请求时需要提供以下数据）
目的：用于 svn hook 脚本远程调用触发 jenkins 的任务。
```bash
【jenkins_api_token】
右上角用户名-菜单-设置
    API Token
        单击: [Show API Token...]
        User ID: admin
        API Token: xxxxxx

则：
jenkins_api_token='admin:xxxxxx'


【jenkins_crumb】（在每个客户端上执行的结果是不一样的）
执行：
    curl -s 'http://admin:password@${jenkins_server}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'
得到：
    Jenkins-Crumb:35b5802e2f723e6ff7c3c0f1eb4097cb

则：
    jenkins_crumb='Jenkins-Crumb:35b5802e2f723e6ff7c3c0f1eb4097cb'

【jenkins_token】
项目-配置-构建触发器
    触发远程构建 (例如,使用脚本)	Help for feature: 触发远程构建 (例如,使用脚本)
        身份验证令牌：	test_build_token
    Use the following URL to trigger build remotely: JENKINS_URL/job/projectname/build?token=TOKEN_NAME 或者 /buildWithParameters?token=TOKEN_NAME
    Optionally append &cause=Cause+Text to provide text that will be included in the recorded build cause.

则：
    jenkins_token='test_build_token'

最终使用curl来调用：
    curl -s \
-H "${jenkins_crumb}" \
--data-urlencode json="
{
    \"parameter\": [
        {
            \"name\": \"string_key_1\",
            \"value\": \"${string_key_1}\"
        },
        {
            \"name\": \"string_key_2\",
            \"value\": \"${string_key_2}\"
        }
    ]
}
" "http://${jenkins_api_token}@${jenkins_server}/job/projectname/build?token=${jenkins_token}"
```


### 四、执行任务
1. 新增一个 salve 节点
> 提示：先手动 ssh 测试一下连通性。

```
选择菜单：“Jenkins-系统管理-管理节点-新建节点”
调整部分配置：
------------------------------------------------------------------------------
	Name:                    n32
    远程工作目录:              /home/jenkins
    用法:                      只允许运行绑定到这台机器的Job
    启动方法:                launch slave agents on unix machines via ssh
    Host:                    172.17.0.1
    Credentials:             （可选 ssh password 或 key 认证）
保存
------------------------------------------------------------------------------
```

2. 创建一个任务
```
选择菜单：“Jenkins-新建”
------------------------------------------------------------------------------
    Item名称:                job1
    （勾选）构建一个自由风格的软件项目

确定

    项目名称:                job1
    （勾选）Restrict where this project can be run
                Label Expression: n32

    构建:
    （选择）Execute shell
                Command:
                    echo "[`date`] execute shell from jenkins." >>test.log

保存
------------------------------------------------------------------------------
```

3. 执行任务
```
选择菜单：“立即构建”
页面变成：
------------------------------------------------------------------------------
Project job1

添加说明
禁用项目
	工作区
	最新修改记录
相关连接

Last build(#1),16 秒之前
Last stable build(#1),16 秒之前
Last successful build(#1),16 秒之前
Last completed build(#1),16 秒之前
------------------------------------------------------------------------------
```

4. 验证任务
```
查看工作区：
------------------------------------------------------------------------------
Workspace of job1 on n32

	test.log	59 B	查看
 (打包下载全部文件)
------------------------------------------------------------------------------

继续查看 test.log
------------------------------------------------------------------------------
[Thu Jun 30 11:18:43 CST 2016] execute shell from jenkins.
------------------------------------------------------------------------------

重复构建2次后，再次查看内容：
------------------------------------------------------------------------------
[Thu Jun 30 11:18:43 CST 2016] execute shell from jenkins.
[Thu Jun 30 11:20:05 CST 2016] execute shell from jenkins.
[Thu Jun 30 11:20:11 CST 2016] execute shell from jenkins.
------------------------------------------------------------------------------

在左下方可以看到构建历史，内容类似这样：
------------------------------------------------------------------------------
Build History  构建历史

Success > 控制台输出 #3 2016-6-30 上午3:20
Success > 控制台输出 #2 2016-6-30 上午3:20
Success > 控制台输出 #1 2016-6-30 上午3:18
------------------------------------------------------------------------------
```

5. 小结
```
本次示例，尚未使用 svn，git，仅简单示范在指定的节点上执行 shell 任务，体现出 jenkins 大致上是如何工作的。
```


### 插件
##### git/gitlab插件的使用示例

> 通常是这样的思路：
dev -> push -> gitlab(with web hook) -> jenkins-gitlab-hook -> build

1. 插件
```
credentials：管理帐号密码
git：
gitlab-hook：配合gitlab项目下触发自动构建

选择菜单：“Jenkins-系统管理-插件管理”
-“可选菜单”：搜索需要的插件（当然，启动jenkins时引导程序已经安装了常用的插件）
-“高级”：可以手动下载.jpi后缀的插件，上传到jenkins上来安装。

插件示例：
[root@tvm01 plugins]# ls *.jpi
ace-editor.jpi                 durable-task.jpi                git-server.jpi       matrix-project.jpi           plain-credentials.jpi  token-macro.jpi                 workflow-scm-step.jpi
antisamy-markup-formatter.jpi  email-ext.jpi                   gradle.jpi           momentjs.jpi                 resource-disposer.jpi  windows-slaves.jpi              workflow-step-api.jpi
ant.jpi                        external-monitor-job.jpi        handlebars.jpi       pam-auth.jpi                 ruby-runtime.jpi       workflow-aggregator.jpi         workflow-support.jpi
bouncycastle-api.jpi           git-client.jpi                  icon-shim.jpi        pipeline-build-step.jpi      scm-api.jpi            workflow-api.jpi                ws-cleanup.jpi
branch-api.jpi                 github-api.jpi                  jquery-detached.jpi  pipeline-graph-analysis.jpi  script-security.jpi    workflow-basic-steps.jpi
build-timeout.jpi              github-branch-source.jpi        junit.jpi            pipeline-input-step.jpi      ssh-credentials.jpi    workflow-cps-global-lib.jpi
cloudbees-folder.jpi           github.jpi                      ldap.jpi             pipeline-milestone-step.jpi  ssh-slaves.jpi         workflow-cps.jpi
credentials-binding.jpi        github-organization-folder.jpi  mailer.jpi           pipeline-rest-api.jpi        structs.jpi            workflow-durable-task-step.jpi
credentials.jpi                git.jpi                         mapdb-api.jpi        pipeline-stage-step.jpi      subversion.jpi         workflow-job.jpi
display-url-api.jpi            gitlab-hook.jpi                 matrix-auth.jpi      pipeline-stage-view.jpi      timestamper.jpi        workflow-multibranch.jpi
```

2. 创建一个任务
```
选择菜单：“Jenkins-新建”
    Item名称:                asset
    （勾选）构建一个自由风格的软件项目

确定

    项目名称:                asset
    （勾选）Restrict where this project can be run
                Label Expression: n32
                （注：本例中这个 slave 节点 n32 是使用 linux 帐号 jenkins 通过 ssh 连接到该 salve 节点，因而运行 job 时，也是使用的 jenkins 这个帐号，请合理的使用权限，例如配置sudo来执行命令）
    源码管理:
    Git:
        Repositories
            Repository URL: http://your_gitlab_server/user01/asset.git
            Credentials: gitlab-user01(ADD新增一个相关的帐号密码)
    	Branches to build
            Branch Specifier (blank for 'any'): */master
        源码库浏览器: 自动


    构建:
    （选择）Execute shell
                Command:

                    # setup
                    d_root='/opt/asset'
                    d_target="${d_root}/src_$(date +%Y%m%d_%H%M%S)"
                    d_link="${d_root}/latest"
                    sudo mkdir -p ${d_target}

                    # deploy
                    sudo rsync -av ../asset/ --exclude=".git/" ${d_target}/
                    sudo rm -fv ${d_link}
                    sudo ln -sv ${d_target} ${d_link}
                    sudo /bin/bash ${d_link}/ctl.sh c
                    sudo /bin/bash ${d_link}/ctl.sh t
                    sudo /bin/bash ${d_link}/ctl.sh r

                    # cleanup
                    echo "[-] List dir:"
                    sudo ls -l ${d_root}
                    echo "[-] File was last accessed n*24 hours ago:"
                    sudo find ${d_root} -maxdepth 1 -atime +7 -print |sort
                    sudo find ${d_root} -maxdepth 1 -atime +7 -exec rm -fr {} \;
                    echo "[-] List dir again:"
                    sudo ls -l ${d_root}

保存
```

3. 执行任务
```
选择菜单：“立即构建”
结果：成功，符合预期
```

4. 在gitlab上配置web hook
```
先测试一下 jenkins 插件 gitlab-hook 是否有效：
页面请求：http://ip_of_jenkins:8080/gitlab/build_now
返回结果：
------------------------------------------------------------------------------
repo url could not be found in Gitlab payload or the HTTP parameters:
- body: {}
- parameters: {

}
------------------------------------------------------------------------------

继续，在 gitlab 的项目 asset 页面上，找到“Settings-Web Hooks”
------------------------------------------------------------------------------
URL: http://ip_of_jenkins:8080/gitlab/build_now
Trigger：（勾选）Push events
------------------------------------------------------------------------------

点击“Add Web Hook”添加后，页面下方将出现这样的界面：
------------------------------------------------------------------------------
Web hooks (1)
http://ip_of_jenkins:8080/gitlab/build_now               Test Hook      Remove
Push Events
------------------------------------------------------------------------------
单击：“Test Hook”按钮后，回到jenkins页面，查看是否触发了新的build。
结果：符合预期。
```



##### svn的使用示例

1. 项目配置

【General】
```
项目名称: job02
参数化构建过程
    String parameter
        名字: key01
        默认值: default_not_exist
```

【源码管理】
```
在源码管理模块选择Subversion。
Repository URL中填入svn repo地址。【特别注意：注1】
Credentials中添加svn服务器的用户名和密码。
```

> 注1
```
重点：为了避免Jenkins master时区和SVN服务器时区不一致，请在repo地址末尾添加 @HEAD，例如：http://svn_server/repo_name@HEAD
否则 jenkins 构建时 update svn 仓库是根据 jenkins 服务器当前的时间来拉取的，极可能拉取到的是一个旧的 svn 版本，从而引发错误。
jenkins 上的相关说明：
Specify the subversion repository URL to check out, such as "http://svn.apache.org/repos/asf/ant/". You can also add "@NNN" at the end of the URL to check out a specific revision number, if that's desirable. This works for Subversion Revision Keywords and Dates like e.g. "HEAD", too.
When you enter URL, Jenkins automatically checks if Jenkins can connect to it. If access requires authentication, it will ask you the necessary credential. If you already have a working credential but would like to change it for other reasons, click this link and specify different credential.
During the build, revision number of the module that was checked out is available through the environment variable SVN_REVISION, provided that you are only checking out one module. If you have multiple modules checked out, use the svnversion command. If you have multiple modules checked out, you can use the svnversion command to get the revision information, or you can use the SVN_REVISION_<n> environment variables, where <n> is a 1-based index matching the locations configured. The URLs are available through similar SVN_URL_<n> environment variables.

svn的文档参考：
http://svnbook.red-bean.com/en/1.5/svn.tour.revs.specifiers.html
```

> 案例
```
jenkins构建过程中，遇到一个问题：获取 svn postcommit 触发传递的参数和作者信息，出现混乱，初步判断和 jenkins 服务器停机维护有关系。
注意到以下提示：
Updating http://svn_server/repo_name at revision '2017-09-20T15:52:45.978 +0800'
U         xxxx
At revision 312

WARNING: clock of the subversion server appears to be out of sync. This can result in inconsistent check out behavior.


提交版本313到svn -> svn hook postcommit 请求 jenkins 远程API -> 触发任务：http://jenkins_server/job/test01/401/changes -> 此处却获取到svn版本312的内容

核对时间发现：
15：53由版本313触发的构建
在 jenkins 服务器上的日志显示 update 的 svn 仓库版本却是 312，这是因为构建时指定了版本的时间为15:52
Updating http://svn_server/repo_name at revision '2017-09-20T15:52:45.978 +0800'


小结：初步判断是jenkins服务器今天关机维护后，时间没及时同步导致的异常。
解决方法：在svn仓库的url后指定 @HEAD
```


【构建触发器】
```
（注：在svn中使用hook脚本过滤出最新版本中有变动的image目录名称作为参数传递到这里来build）
✔触发远程构建 (例如,使用脚本)
    身份验证令牌：test_build_token
```

【构建】
```
选择：Execute shell
    Command: （脚本略）
```

【构建后操作】
```
选择：Editable Email Notification

    单击: [Advanced Settings...]

    Triggers:   Always
                Send To
                    Developers

注1：目前jenkins未接入ldap，当svn用户提交后，jenkins会自动记录该用户，但svn提交的信息中只有用户名，没有邮箱信息（这点和git不一样），且该用户并未激活，需要激活（在jenkins中给该用户设置密码）后才能给该用户发送邮件，默认使用系统全局设置中的邮件后缀。
```

2. 配置 svn 仓库
```
增加一个 hook 用来传递参数，并调用远程api
首先，通过 svnlook changed -r ${svn_repository_revision} ${svn_repository} 来获取提交的内容，解析参数传递出去
其次，通过调用远程api来触发build
```





### ZYXW、参考
1. [doc](http://pkg.jenkins-ci.org/redhat-stable/)
2、[gitlab hook](https://github.com/elvanja/jenkins-gitlab-hook-plugin#build-now-hook)
3. [Running jenkins jobs via command line](http://www.inanzzz.com/index.php/post/jnrg/running-jenkins-build-via-command-line)
4. [使用阿里云容器服务Jenkins实现持续集成和Docker镜像构建(updated on 2017.3.3)](https://yq.aliyun.com/articles/53971)
5. [docker-hub](https://hub.docker.com/r/jenkins/jenkins/)
