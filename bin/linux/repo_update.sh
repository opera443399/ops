#!/bin/bash
#
# 2015/7/17

f_log='/tmp/repo_update_run.log'

if [ -f /var/lock/subsys/repo_update ]; then
    echo "[`date`] 同步任务已经在执行中。" >>${f_log}
    exit 0
fi

d_centos='/data/yum/repo/centos/6'
d_epel='/data/yum/repo/epel/6'
-d ${d_centos} ||mkdir -p ${d_centos}
-d ${d_epel} ||mkdir -p ${d_epel}


touch /var/lock/subsys/repo_update

### centos ###
echo "[`date`] 开始同步centos"  >>${f_log} 
rsync -avzP --delete --delete-excluded --exclude "isos" --exclude "i386" rsync://mirrors.ustc.edu.cn/centos/6/ /data/yum/repo/centos/6/ 2>>${f_log}
echo "[`date`] 操作结束。"  >>${f_log} 
### epel ###
echo "[`date`] 开始同步epel"  >>${f_log} 
rsync -avzP --delete  --delete-excluded --exclude "i386" --exclude "ppc64" rsync://mirrors.ustc.edu.cn/epel/6/ /data/yum/repo/epel/6/ 2>>${f_log}
echo "[`date`] 操作结束。"  >>${f_log} 

rm /var/lock/subsys/repo_update
echo "[`date`] 完成本次任务。"  >>${f_log} 

chown -R apache:apache /data/yum/repo

