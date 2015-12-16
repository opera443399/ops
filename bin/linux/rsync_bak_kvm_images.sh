#!/bin/bash
#
# 2015/12/16

s_vm='e01.test'                                         # 源 vm 的名称
s_vm_clone="${s_vm}-clone"                              # 克隆后的 vm 名称 
d_vm_img='/data/kvm/images'                             # 源 vm 的磁盘镜像目录
f_vm_img_clone="${d_vm_img}/${s_vm}-vda-clone.qcow2"    # 源 vm 的磁盘镜像文件路径
d_bak_root="/data/backup/VMs/${s_vm}"                   # 本地 备份目录
s_date=$(date +%Y%m%d)                                  # 日期
d_clone="${d_bak_root}/${s_date}"                       # 当前备份存放目录
d_logs='/data/backup/logs'                              # 备份日志存放目录
f_bak_log="${d_logs}/clone_${s_date}.log"               # 日志文件路径

function do_clone_vm() {
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
    cp -fv /etc/libvirt/qemu/${s_vm}.xml ${d_clone}
    mv -fv /etc/libvirt/qemu/${s_vm_clone}.xml ${d_clone}
    mv -fv ${f_vm_img_clone} ${d_clone} 
    echo "[2] `date` [INFO] step 2 完成。"
    ### 【3】
    echo "[3] `date` [INFO] 移除克隆的 VM"
    virsh undefine ${s_vm_clone}
    echo "[3] `date` [INFO] step 3 完成。"
}


function do_clean() {
    echo "[4] `date` [INFO] 清理7天前的 VM"
    find ${d_bak_root} -mtime +7 -print
    find ${d_bak_root} -mtime +7 -delete
    echo "[4] `date` [INFO] step 4 完成。"
}


function do_rsync() {
    echo "[5] `date` [INFO] 归档到外部存储。"
    rsync -av --delete --password-file=/etc/rsync.pass $1  backup@10.50.200.93::bak_kvm_images
    echo "[5] `date` [INFO] step 5 完成。"
}


function do_bak() {
    mkdir -pv ${d_clone} ${d_logs}
    do_clone_vm
    do_clean
    do_rsync ${d_bak_root}
}


function do_alert() {
    do_bak >${f_bak_log} 2>&1
    if [ $? -eq 0 ];then
        retval="OK"
    else
        retval="Failed"
    fi

    mail_bin="sendEmail -s smtp.xxx.com \
                        -xu f@xxx.com \
                        -xp xxx \
                        -f f@xxx.com \
                        -o message-charset=utf-8"
    to="me@xxx.com"
    subject="sz kvm backup ${retval}"
    body="from ${HOSTNAME}: $0"
    ${mail_bin} -t ${to} -u ${subject} -m ${body} -a ${f_bak_log}
}

do_alert
