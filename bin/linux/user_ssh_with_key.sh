#!/bin/bash
# 创建用户，并追加ssh public key
# 使用这个命令来生成key
# ssh-keygen -t rsa -b 2048 -C you_comment_here -f filename
# 例如：
# ssh-keygen -t rsa -b 2048 -C yourname@office -f yourname
# 将生成个文件：
# yourname      私钥
# yourname.pub  公钥
# 2015/07/14

username='yourname'
useradd ${username}
id ${username}
 
[ -d /home/${username}/.ssh ] || mkdir -p /home/${username}/.ssh
 
cat <<_PUBKEY >> /home/${username}/.ssh/authorized_keys
paste your public key(#cat yourname.pub) here
_PUBKEY
 
chmod 700 /home/${username}/.ssh
chmod 600 /home/${username}/.ssh/authorized_keys
chown -R ${username}:${username} /home/${username}/.ssh
 
cat /home/${username}/.ssh/authorized_keys
