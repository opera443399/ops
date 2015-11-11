#!/bin/bash
#
# 2015/10/27

s_vm='e01.test'                                         # 源 vm 的名称: e01.test
s_vm_clone="${s_vm}-clone"                              # 克隆后的 vm 名称: e01.test-clone
d_vm_img='/data/kvm/images'                             # 源 vm 的磁盘镜像目录
f_vm_img_clone="${d_vm_img}/${s_vm}-vda-clone.qcow2"    # 源 vm 的磁盘镜像文件路径
d_bak_root="/data/backup/VMs/${s_vm}"                   # 本地 备份目录
d_standby_root="/backup/${s_vm}"                        # 外部 备份目录
s_date=$(date +%Y%m%d)                                  # 日期: 20151027
s_date_3=$(date -d "3 days ago" +%Y%m%d)                # 日期: 20151024
s_date_7=$(date -d "7 days ago" +%Y%m%d)                # 日期: 20151020
d_clone="${d_bak_root}/${s_date}"                       # 当前备份存放目录: /data/backup/VMs/e01.test/20151027
d_clone_3="${d_bak_root}/${s_date_3}"                   # 3天前备份存放目录: /data/backup/VMs/e01.test/20151024
d_standby_7="${d_standby_root}/${s_date_7}"             # 7天前备份存放目录: /data/backup/VMs/e01.test/20151020
mkdir -pv ${d_clone}
mkdir -pv ${d_standby_root}


function clone_vm() {
    ### 【1】
    echo '#virsh# list --all' && virsh list --all |grep ${s_vm}
    echo "[1] `date` [INFO] 准备克隆。"
    virsh suspend ${s_vm}
    echo '#virsh# list --all' && virsh list --all |grep ${s_vm}
    ret=$?
    virt-clone -o e01.test --auto-clone
    [ ${ret} -eq 0 ] && virsh resume ${s_vm}
    echo '#virsh# list --all' && virsh list --all |grep ${s_vm}
    echo "[1] `date` [INFO] step 1 完成。"
    ### 【2】
    echo "[2] `date` [INFO] 收集 xml 和 images 并拷贝到本地存储。"
    cp -av /etc/libvirt/qemu/${s_vm}.xml ${d_clone}
    mv -fv /etc/libvirt/qemu/${s_vm_clone}.xml ${d_clone}
    mv -fv ${f_vm_img_clone} ${d_clone} 
    echo "[2] `date` [INFO] step 2 完成。"
    ### 【3】
    echo "[3] `date` [INFO] 归档到外部存储。"
    cp -afv ${d_clone} ${d_standby_root}
    echo "[3] `date` [INFO] step 3 完成。"
    ### 【4-1】
    echo "[4-1] `date` [INFO] 移除克隆的 VM"
    virsh undefine ${s_vm_clone}
    echo "[4-1] `date` [INFO] 列出目录：${d_bak_root}" && ls ${d_bak_root}
    echo "[4-1] `date` [INFO] 清理本地超过3天的副本。"
    [ -d ${d_clone_3} ] && rm ${d_clone_3} -frv
    echo "[4-1] `date` [INFO] 列出目录：${d_bak_root}" && ls ${d_bak_root}
    echo "[4-1] `date` [INFO] step 4-1 完成。"
    ### 【4-2】
    echo "[4-2] `date` [INFO] 列出目录：${d_standby_root}" && ls ${d_standby_root}
    echo "[4-2] `date` [INFO] 清理外部存储超过7天的副本。"
    [ -d ${d_standby_7} ] && rm ${d_standby_7} -frv
    echo "[4-2] `date` [INFO] 列出目录：${d_standby_root}" && ls ${d_standby_root}
    echo "[4-2] `date` [INFO] step 4-2 完成。"
}

##-
clone_vm

#mkdir -p /data/backup/logs && /bin/bash /data/ops/bin/backupVM.sh >/data/backup/logs/clone_$(date +%Y%m%d).log 2>&1
# crontab
#0 2 * * * /bin/bash /data/ops/bin/backupVM.sh >/data/backup/logs/clone_$(date +\%Y\%m\%d).log 2>&1 &

