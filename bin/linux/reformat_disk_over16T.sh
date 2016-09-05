#!/bin/bash
#
#2016/9/1

yum -y install lvm2 xfsprogs
df -h
umount /data/
sed -i '/\/data/d' /etc/fstab 
fdisk -l /dev/sdb
fdisk /dev/sdb <<_EOF
p
d
p
w
_EOF
sleep 5
pvcreate /dev/sdb
vgcreate vg0 /dev/sdb
lvcreate -l 100%FREE -n lv01 vg0
mkfs.xfs -f -i size=512 /dev/vg0/lv01
sleep 5
mkdir -p /data 
cat <<_EOF >>/etc/fstab
UUID=$(blkid /dev/vg0/lv01 |cut -d'"' -f2) /data                   xfs     defaults        0 0
_EOF
mount -a
df -h
