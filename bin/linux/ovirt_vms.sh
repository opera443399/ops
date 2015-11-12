#!/bin/bash
# 
# 2015/11/12
# __version__='0.2.3'
# 批量生成一个 IP 段的 vm 信息，指出需要几个 vm 并创建和设置 vm 的主机名，root密码，网络配置。
# requires: ovirt_randchars.py ovirt_api.sh

s_vm_subnet='10.50.200'
s_vm_netmask='255.255.255.0'
s_vm_gateway="${s_vm_subnet}.1"
s_vm_dns='223.5.5.5'

f_ip_pool="pool.${s_vm_subnet}"
f_vms="vms.${s_vm_subnet}"

## 根据指定的网段，初始化 IP 池
##（注：此处细节先略过，假设是固定一致的 IP 范围）
function pool(){
    for i in {2..254};
    do
        ip="${s_vm_subnet}.$i"
        echo "${ip}"
    done >${f_ip_pool}
}

## 生成指定网段 的 vm 数据
function prepare() {
    local idx=1
    local s_domain='company.com'
    echo 'STATE_CREATE,STATE_INIT,VM_NAME,PASSWORD VM_IP VM_NETMASK VM_GATEWAY VM_DNS' >${f_vms}
    pool

    for i in `cat ${f_ip_pool}`;
    do  
        local s_vm_ip="$i"
        ## 构造 vm 名称  vm_ip3_ip4.domain
        local s_vm_name="vm_$(echo ${s_vm_ip} |awk -F'.' '{print $3"_"$4}').${s_domain}"
        local s_password=$(python ovirt_randchars.py)
        msg="CREATE_NO,INIT_NO,${s_vm_name},${s_password} ${s_vm_ip} ${s_vm_netmask} ${s_vm_gateway} ${s_vm_dns}"
        echo ${msg} >>${f_vms}
    done
}

## 创建指定数量的 vm
function get() {
    local cnt=$1

    for ((i=1;i<=${cnt};i++))
    do
        grep 'CREATE_NO' ${f_vms} >/dev/null
        if [ $? -eq 1 ]; then
            echo "`date` [ERROR] VM存量不足。" 
            exit 1
        fi
        local s_row=`grep 'CREATE_NO' ${f_vms} |head -n 1`
        local s_vm_name=`echo ${s_row} |cut -d',' -f3`
        local s_args=`echo ${s_row} |cut -d',' -f4`

        echo -e "\n[$i] -- 创建：${s_vm_name}"
        echo '--------------------------------'
        ## 需要 ovirt_api.sh
        /bin/bash ovirt_api.sh create ${s_vm_name}
        local ret=$?
        if [ ${ret} -eq 0 ]; then
            ## 更新 CREATE 状态
            sed -i -r "s/^CREATE_NO,(.*),${s_vm_name},(.*)/CREATE_YES,\1,${s_vm_name},\2/" ${f_vms}
            echo "`date` [INFO] 已加入 VM 池。"
            echo '--------------------------------'
            init ${s_vm_name}
        else
            echo "返回值：${ret}"
            cat "${s_vm_name}.create.xml" |grep 'already in use' >/dev/null
            is_vm_exist=$?
            if [ $is_vm_exist -eq 0 ]; then
                sed -i -r "s/^CREATE_NO,(.*),${s_vm_name},(.*)/CREATE_YES,\1,${s_vm_name},\2/" ${f_vms}
                echo "`date` [INFO] 已更新 VM 池。"
                echo '--------------------------------'
                init ${s_vm_name}
                continue
            fi
            echo "`date` [ERROR] 创建 VM 时，遇到异常。"
            exit 2
        fi
    done
}

## 启动时运行一次 cloud-init 来设置 vm
function init() {
    local s_vm_name=$1
    grep ",${s_vm_name}," ${f_vms} >/dev/null
    if [ $? -eq 1 ]; then
        echo "`date` [ERROR] VM 不存在。" 
        exit 1
    fi 
    local s_row=`grep "${s_vm_name}" ${f_vms} |head -n 1`
    local s_vm_name=`echo ${s_row} |cut -d',' -f3`
    local s_args=`echo ${s_row} |cut -d',' -f4`

    echo -e "\n[$i] -- 启动时运行一次 cloud-init：${s_vm_name}"
    echo '--------------------------------'
    ## 需要 ovirt_api.sh
    /bin/bash ovirt_api.sh init ${s_vm_name} ${s_args}
    local ret=$?
    if [ ${ret} -eq 0 ]; then                  
        sed -i -r "s/^CREATE_YES,(.*),${s_vm_name},(.*)/CREATE_YES,INIT_YES,${s_vm_name},\2/" ${f_vms}
        echo "`date` [INFO] 已启动。"
    else
        echo "`date` [ERROR] 启动时运行一次 cloud-init 遇到异常。"  
        echo "返回值：${ret}"
        return 1
    fi
    echo '--------------------------------'
    return 0
}


function usage() {
    cat <<'_EOF'

usage:
    $0 prepare|get|init

    prepare
    get num
    init vm_name

_EOF
    exit 0
}

case $1 in
    prepare)
        $1
        ;;
    get|init)
        $1 $2
        ;;
    *)
        usage 
esac

