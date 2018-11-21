#!/bin/bash
# 
# 2015/7/31

n_size='2G'
f_vg='vg01'
f_orin='lv01'
f_snap='snap_lv01'
lv_orig="/dev/${f_vg}/${f_orig}"
lv_snap="/dev/${f_vg}/${f_snap}"
d_backup='/data/backup/snapshot'
f_snap="${d_backup}/${f_orig}_$(date +%F).tar.gz"

#1 create 创建快照
lvcreate -L ${n_size} -s -n ${f_snap} ${lv_orig}

#2 mount to tar backup 挂载后压缩备份
test -d ${d_backup} || mkdir -p ${d_backup}/mnt \
&& mount -o remount,ro ${lv_snap} ${d_backup}/mnt \
&& df -h

cd ${d_backup} \
&& tar zcf ${f_snap} mnt/* \
&& ls -lh ${f_snap} 

#3 umount to remove 卸载后移除快照
umount ${d_backup}/mnt && lvremove -f ${lv_snap}

