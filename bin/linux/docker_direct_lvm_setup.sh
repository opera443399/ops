#!/bin/bash
#
#2016/12/8
#v1.0.4 @PC

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
howto:

[1] backup if needed
# mkdir /var/lib/docker.bk
# mv /var/lib/docker/* /var/lib/docker.bk

[2] update docker config
(added to docker.service)
# sed -i '/^ExecStart=/c\ExecStart=/usr/bin/dockerd --storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/docker-thinpool --storage-opt=dm.use_deferred_removal=true --storage-opt=dm.use_deferred_deletion=true' /lib/systemd/system/docker.service 

(added to daemon.json)
# cat /etc/docker/daemon.json
{
  "storage-driver": "devicemapper",
    "storage-opts": [
      "dm.thinpooldev=/dev/mapper/docker-thinpool",
      "dm.use_deferred_removal=true",
      "dm.use_deferred_deletion=true"
    ]
}


[3] restart
# systemctl daemon-reload
# systemctl start docker

[4] validate
# docker info
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


_EOF
