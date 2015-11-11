#!/bin/bash
# 设置ssh的提示内容。
# 2015/8/25

cat << _SSHCONFIG > /etc/ssh/ssh.banner
[-] welcome to the wonderland ...
[^]
  . ____         . ____
 /\  ___ '\     /\  ____'\
 \ \  _  \ \    \ \ \   \/
  \ \ \/\ \/     \ \ \
   \ \  - /       \ \ \
    \ \ \          \ \ \
     \ \ \          \ \ \
      \ \ \          \ \ \ __/\
       \ \ \          \_\/____/
        \_\/
[^] 
[^] '.': hard working now, take care!
_SSHCONFIG
 
sed -i s/^Banner/#Banner/ /etc/ssh/sshd_config 
sed -i /^#Banner/d /etc/ssh/sshd_config 
echo "Banner /etc/ssh/ssh.banner" >>/etc/ssh/sshd_config
service sshd reload
