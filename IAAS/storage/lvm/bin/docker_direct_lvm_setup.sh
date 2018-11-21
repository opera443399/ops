#!/bin/bash
#
#2016/12/8
#v1.0.5 @PC

## 分配一块独立的磁盘供docker使用，本例使用的是 /dev/vdb
dev_name='/dev/vdb'

yum -y -q install lvm2
echo '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
pvcreate ${dev_name}
vgcreate docker ${dev_name}
lvcreate --wipesignatures y -n thinpool docker -l 95%VG
lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG
lvconvert -y --zero n -c 512K --thinpool docker/thinpool --poolmetadata docker/thinpoolmeta
cat <<'_EOF' >/etc/lvm/profile/docker-thinpool.profile
activation {
    thin_pool_autoextend_threshold=80
    thin_pool_autoextend_percent=20
}
_EOF
lvchange --metadataprofile docker-thinpool docker/thinpool
echo '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
lvs -o+seg_monitor
echo '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'

cat <<'_EOF'

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
接下来的操作步骤示例：

[1] 如果 docker 有旧的数据，先推送到registry中再移除；
# mkdir /var/lib/docker.bk
# mv /var/lib/docker/* /var/lib/docker.bk

[2] 更新docker服务的配置：
(方式一： 调整 docker.service 的配置参数)
# sed -i '/^ExecStart=/c\ExecStart=/usr/bin/dockerd --storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/docker-thinpool --storage-opt=dm.use_deferred_removal=true --storage-opt=dm.use_deferred_deletion=true' /lib/systemd/system/docker.service 

(方式二： 在 daemon.json 中配置参数)
# cat /etc/docker/daemon.json
{
    "storage-driver": "devicemapper",
    "storage-opts": [
        "dm.thinpooldev=/dev/mapper/docker-thinpool",
        "dm.use_deferred_removal=true",
        "dm.use_deferred_deletion=true"
    ]
}


[3] 重启服务
# systemctl daemon-reload && systemctl start docker

[4] 验证是否调整完毕
# docker info
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_EOF
