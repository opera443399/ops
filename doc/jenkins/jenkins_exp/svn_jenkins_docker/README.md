svn jenkins docker
------
2017/9/4


(svn-server)
├──exp_repo
│   ├── project_name
│   │   ├── image_name
│   │   │   ├── Dockerfile



svn->
	-->hook(post with parameter::svn_hook_postcommit_dockerfile.sh)->
		-->jenkins(with parameter)->
			-->run(script:jenkins_ctl_dockerfile.sh)->
				-->dockerfile,image or anything you want.
                