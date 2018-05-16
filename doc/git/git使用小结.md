# git使用小结
2018/5/16

> 注释：不定时更新


### 配置

##### config
> 通过 git config 来定义

涉及内容： `git 提交的作者信息`

  - 影响内容：.git/config
  ```bash
  ~]# git config user.name "Jack"
  ~]# git config user.email jack@test.com
  ```

  - 影响内容：~/.gitconfig
  ```bash
  ~]# git config --global user.name "Jack"
  ~]# git config --global user.email jack@test.com
  ```

  - 影响内容：/etc/gitconfig
  ```bash
  ~]# git config --system user.name "Jack"
  ~]# git config --system user.email jack@test.com
  ```



> 通过配置文件来定义
  - 编辑 `.git/config` 变更内容如下
  ```bash
  [user]
          name = Jack
          email = jack@test.com
  ```


##### clone
```bash
git clone https://tester01@github.com/tester01/charade.git
```


##### init
```bash
git init --bare
```


##### branch

* 创建分支：
```bash
[root@dev_08 portainer]# git branch bbb
```

* 查看本地分支：
```bash
[root@dev_08 portainer]# git branch
  bbb
* develop
```

* 使用分支：
```bash
[root@dev_08 portainer]# git checkout bbb
Switched to branch 'bbb'
[root@dev_08 portainer]# git branch
* bbb
  develop
```

* 切换分支：
```bash
[root@dev_08 portainer]# git checkout develop
Switched to branch 'develop'
```

* 删除分支：
```bash
[root@dev_08 portainer]# git branch -d bbb
Deleted branch bbb (was f3a1250).

[root@dev_08 portainer]# git branch
* develop
```

* 列出所有分支：
```bash
[root@dev_08 portainer]# git branch -a
* develop
  remotes/origin/HEAD -> origin/develop
  remotes/origin/angular-loading-bar
  remotes/origin/codefresh-pr1224
  remotes/origin/demo
  remotes/origin/develop
  remotes/origin/docker17
  remotes/origin/feat-add-container-console-on-task-details
  remotes/origin/feat1235-setting-disable-binds
  remotes/origin/feat257-compose-support
  remotes/origin/feat257-stack-deploy
  remotes/origin/feat807-i18n
  remotes/origin/gh-pages
  remotes/origin/master
  remotes/upstream/codefresh-pr996
  remotes/upstream/demo
  remotes/upstream/develop
  remotes/upstream/feat257-compose-support
  remotes/upstream/feat807-i18n
  remotes/upstream/gh-pages
  remotes/upstream/master
```

* 切换到远程分支
```bash
[root@dev_08 confd]# git branch
* master
[root@dev_08 confd]# git branch -a
* master
  remotes/origin/HEAD -> origin/master
  remotes/origin/exp-keep-backend-etcd-only
  remotes/origin/fix-integration-etcd-curl-err
  remotes/origin/gh-pages
  remotes/origin/master
[root@dev_08 confd]# git checkout -b exp-keep-backend-etcd-only remotes/origin/exp-keep-backend-etcd-only
Branch exp-keep-backend-etcd-only set up to track remote branch exp-keep-backend-etcd-only from origin.
Switched to a new branch 'exp-keep-backend-etcd-only'
[root@dev_08 confd]# git branch
* exp-keep-backend-etcd-only
  master
```

##### remote
* git push时，会报错：
  ```
  error: The requested URL returned error: 403 Forbidden while accessing https://github.com/tester01/charade.git/info/refs

  fatal: HTTP request failed
  ```

  解决办法：
  ```bash
  git remote set-url origin https://tester01@github.com/tester01/charade.git
  ```

* 当我 fork 一个项目后，如果 upstream 有更新，如何合并到自己 fork 的项目中

  - 查看 remote 的状态：
  ```bash
  [root@dev_08 portainer]# git remote -v
  origin	https://github.com/opera443399/portainer.git (fetch)
  origin	https://github.com/opera443399/portainer.git (push)
  ```

  - 增加一个 upstream 到 remote 中：
  ```bash
  [root@dev_08 portainer]# git remote add upstream https://github.com/portainer/portainer.git
  [root@dev_08 portainer]# git remote -v
  origin	https://github.com/opera443399/portainer.git (fetch)
  origin	https://github.com/opera443399/portainer.git (push)
  upstream	https://github.com/portainer/portainer.git (fetch)
  upstream	https://github.com/portainer/portainer.git (push)
  ```

  - 获取 upstream 的代码：
  ```bash
  [root@dev_08 portainer]# git fetch upstream
  remote: Counting objects: 249, done.
  remote: Compressing objects: 100% (3/3), done.
  remote: Total 249 (delta 176), reused 179 (delta 176), pack-reused 70
  Receiving objects: 100% (249/249), 37.10 KiB | 0 bytes/s, done.
  Resolving deltas: 100% (176/176), completed with 134 local objects.
  From https://github.com/portainer/portainer
   * [new branch]      codefresh-pr996 -> upstream/codefresh-pr996
   * [new branch]      demo       -> upstream/demo
   * [new branch]      develop    -> upstream/develop
   * [new branch]      feat257-compose-support -> upstream/feat257-compose-support
   * [new branch]      feat807-i18n -> upstream/feat807-i18n
   * [new branch]      gh-pages   -> upstream/gh-pages
   * [new branch]      master     -> upstream/master
   * [new tag]         1.15.0     -> 1.15.0
  ```


  - 确认分支后，开始 merge 代码：
  ```bash
  [root@dev_08 portainer]# git branch
  * develop
  [root@dev_08 portainer]# git merge upstream/develop
  [root@dev_08 portainer]# git log --oneline -3
  730925b fix(containers): fix an issue with filters
  7eaaf9a feat(container-inspect): add the ability to inspect containers
  925326e feat(volume-details): show a list of containers using the volume
  ```

  - 推送到自己 fork 的项目中：
  ```bash
  git push
  ```




### 回滚

##### git revert
保存了 history 信息，适用于已经 push 到 public repository 后，要回滚

##### git reset
清除了 history 信息，很暴力，适用于 local 开发时要回滚

**实例：** 回退到上一个版本
```bash
[root@dev_08 portainer]# git log -2 --oneline
0dd239c add console on 'Task details' view; move tasks to the top
730925b fix(containers): fix an issue with filters
[root@dev_08 portainer]# git reset --hard HEAD^
HEAD is now at 730925b fix(containers): fix an issue with filters
```


### 提交变更的常用操作

##### 查看当前的状态
```bash
[root@dev_08 confd]# git status
# On branch exp-keep-backend-etcd-only
nothing to commit, working directory clean

[root@dev_08 portainer]# git status
# On branch feat-add-container-console-on-task-details
# Changes not staged for commit:
#   (use "git add <file>..." to update what will be committed)
#   (use "git checkout -- <file>..." to discard changes in working directory)
#
#	modified:   app/components/service/includes/tasks.html
#	modified:   app/components/service/service.html
#	modified:   app/components/sidebar/sidebarController.js
#	modified:   app/components/task/task.html
#	modified:   build/build_in_container.sh
#
no changes added to commit (use "git add" and/or "git commit -a")
```

##### 丢弃某个文件的修改（commit前操作）
```bash
[root@dev_08 portainer]# git checkout -- build/build_in_container.sh
[root@dev_08 portainer]# git status
# On branch feat-add-container-console-on-task-details
# Changes not staged for commit:
#   (use "git add <file>..." to update what will be committed)
#   (use "git checkout -- <file>..." to discard changes in working directory)
#
#	modified:   app/components/service/includes/tasks.html
#	modified:   app/components/service/service.html
#	modified:   app/components/sidebar/sidebarController.js
#	modified:   app/components/task/task.html
#
no changes added to commit (use "git add" and/or "git commit -a")
```

##### add

将当前路径下的所有文件添加到VCS中：
```bash
git add .
```

##### commit

在编辑器中写入修改信息后再提交：
```bash
[root@dev_08 portainer]# git commit -a

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
# On branch feat-add-container-console-on-task-details
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#       modified:   app/components/service/includes/tasks.html
#       modified:   app/components/service/service.html
#       modified:   app/components/sidebar/sidebarController.js
#       modified:   app/components/task/task.html
#
```

上述，将打开一个编辑器来编辑内容，保存后：

```bash
".git/COMMIT_EDITMSG" 23L, 1300C written
[feat-add-container-console-on-task-details c42aaa7] add console on 'Task details' view; move tasks to the top
 4 files changed, 14 insertions(+), 4 deletions(-)

[root@dev_08 portainer]# git log -1 --oneline
c42aaa7 add console on 'Task details' view; move tasks to the top
[root@dev_08 portainer]# git status
# On branch feat-add-container-console-on-task-details
nothing to commit, working directory clean
```

或者，简单的写一行信息并提交：

```bash
git commit -am
```

##### push

  - 简单的push到远端

  ```bash
  git push
  ```

  - push到远端分支

  ```bash
  [root@dev_08 portainer]# git push origin feat-add-container-console-on-task-details:feat-add-container-console-on-task-details
  Password for 'https://opera443399@github.com':
  Counting objects: 23, done.
  Delta compression using up to 4 threads.
  Compressing objects: 100% (8/8), done.
  Writing objects: 100% (12/12), 1.67 KiB | 0 bytes/s, done.
  Total 12 (delta 8), reused 5 (delta 4)
  remote: Resolving deltas: 100% (8/8), completed with 8 local objects.
  To https://opera443399@github.com/opera443399/portainer.git
   * [new branch]      feat-add-container-console-on-task-details -> feat-add-container-console-on-task-details
  ```


##### log

  - 查看最近5条日志：
  ```bash
  git log -5
  ```

  - 查看最近5条日志（单行）：
  ```bash
  git log -5 --oneline
  ```

  - 查看最新提交的id：
  ```bash
  git rev-parse --short HEAD
  git log -n 1 --pretty=format:'%h'
  ```


##### 变更

  - 查看最新的变更：
  ```bash
  git whatchanged -1
  ```

  - 查看最新的变更，简化：
  ```bash
  git diff-tree --no-commit-id --name-status -r HEAD
  ```



### XYWX. 参考
1. [gitlab或github下fork后如何同步源的新更新内容？](https://www.zhihu.com/question/28676261)
2. [回滚](https://www.atlassian.com/git/tutorials/undoing-changes)
