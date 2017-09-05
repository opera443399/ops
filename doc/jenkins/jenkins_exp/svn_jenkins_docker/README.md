svn jenkins docker
------
2017/9/5

1、目录结构
(svn-server)
├──exp_repo
│   ├── project_name
│   │   ├── image_name
│   │   │   ├── Dockerfile



2、流程
svn->
	-->hook(post with parameter::svn_hook_postcommit_dockerfile.sh)->
		-->jenkins(with parameter)->
			-->run(script:jenkins_ctl_dockerfile.sh)->
				-->dockerfile,image(or anything you want)->
                    -->email
      
      
3、QA
 
1）如何才能收到邮件
如果使用的jenkins自带的认证功能，需要注意以下内容：

svn用户提交时，只有用户名，没有邮箱，但jenkins会提取出svn用户名，加上全局的邮箱后缀来组合出完整的邮箱。
但，如果该用户并未在jenkins上激活（选择该用户，设置密码），则无法发送邮件。
 
因此，需要做的操作是：第一次提交svn后，在jenkins中设置下该用户的密码，后续提交将能收到邮件。
 

 
2）如何做测试
【方案1】脚本
测试所有EXPOSE的端口
目前是根据 EXPOSE 指令定义的端口，使用 curl 请求，根据返回值来判断端口的存活状态。（参考脚本中这一个函数：unittest_tcp_port）
注：假设在 EXPOSE 中定义了一个不存在的端口（例如 22222），docker建立了端口的映射关系（8080:22222），此时 通过 curl 请求 127.0.0.1:8080 时会发现 tcp 链路可达，但并不代表该端口是可用的。

 
【方案2】docker HEALTHCHECK  指令
HEALTHCHECK --interval=10s --timeout=2s --retries=3 \
  CMD curl --silent --fail localhost:5000 || exit 1
 
 
3）image name 的规范

SVN下Dockerfile路径：
/repo_dockerfile/job01/app/Dockerfile

镜像路径：
registry.xxx.com/mytest/job01_app:201707_1622


 
4）registry
registry.xxx.com/mytest


 
5）如何跳过测试环节呢？
在 dockerfile 中增加关键字：
# TEST_OFF
来跳过测试环节，build后直接push。
否则，在 dockerfile 中必须存在有效的 EXPOSE 指令


 
6）合理使用COPY目录的功能
理由：目录下包含了 .svn 目录，每次提交都会更新，导致使用了COPY目录的这一层无法使用cache来构建。
可以使用以下方式替代：
a）增加 .dockerignore
b）打包目录并使用 ADD xxx.tar.gz


