#!/bin/bash
# 
# 2016/4/26
# __version__='0.2.10'
# for ovirt-engine-3.6.0.3

#
DEBUG=0
## ovirt engine 信息
oe_url='https://e01.test/api'
oe_user='admin@internal'
oe_password='TestVM'

## curl 运行时固有的参数
curl_opts='curl -s --cacert ca.crt'

## 列出所有的 vm
function vm_list() {
    local s_vm_name=$1
    local f_xml="vms.xml"
    
    ${curl_opts} \
-H "Content-Type: application/xml" \
-u "${oe_user}:${oe_password}" \
"${oe_url}/vms" -o ${f_xml}
    return 0
}

## 获取 vm id
function vm_uuid() {
    local s_vm_name="$1"
    local f_xml="vms.xml"
    
    vm_list
    s_vm_id=`grep -vE 'description|comment' ${f_xml} |grep -A 1 "<name>${s_vm_name}</name>"|grep 'href=' |cut -d'"' -f2 |cut -d'/' -f4`
    if [ -z ${s_vm_id} ]; then
        echo '[ERROR] Not found: VM id'
        exit 1
    fi
    return 0
}

## 获取 vm 的状态
function vm_state() {
    local s_vm_name="$1"   
    vm_uuid ${s_vm_name}
    local f_xml="${s_vm_name}.state.xml"
    local state='unknown'
        
    echo -e '--------------------------------\n'
    echo -n 'Waiting..'
    while true
    do  
        ${curl_opts} \
-H "Content-Type: application/xml" \
-u "${oe_user}:${oe_password}" \
"${oe_url}/vms/${s_vm_id}" -o ${f_xml}

        state=`sed -nr 's/(.*)<state>(.*)<\/state>(.*)/\2/p' ${f_xml}`
        case ${state} in
            down)
                echo ' vm is down.'              
                break
                ;;
            up)
                echo ' vm is up.'
                break
                ;; 
            *)
                [ ${DEBUG} -eq 1 ] && echo " vm state: ${state}" || echo -n '.'
                sleep 1
        esac
    done
    echo -e '--------------------------------\n'
    echo "vm: ${s_vm_name}, id: ${s_vm_id}"
    [ ${DEBUG} -eq 0 ] && rm -fv ${f_xml}
    exit 0
}

## 检查 curl 请求返回的结果
function check_fault() {
    local f_xml=$1
    
    grep 'fault' ${f_xml} >/dev/null
    local r1=$?
    grep 'Request syntactically incorrect' ${f_xml} >/dev/null
    local r2=$?
    if [ $r1 -eq 0 ]; then
        echo "result: failed"
        echo "reason: `sed -nr 's/(.*)<reason>(.*)<\/reason>(.*)/\2/p' ${f_xml}`"
        echo "detail: `sed -nr 's/(.*)<detail>(.*)<\/detail>(.*)/\2/p' ${f_xml}`"
        exit 1
    fi
    if [ $r2 -eq 0 ]; then
        echo 'result: Request syntactically incorrect'
        exit 2
    fi

    state=`sed -nr 's/(.*)<state>(.*)<\/state>(.*)/\2/p' ${f_xml}`
    echo "result: ${state}"
    return 0
}

## 启动 vm
function vm_start() {
    local s_vm_name="$1"
    vm_uuid ${s_vm_name}
    local f_xml="${s_vm_name}.start.xml"
    
    ${curl_opts} \
-H "Content-Type: application/xml" \
-u "${oe_user}:${oe_password}" \
-d "
<action>
  <vm>
    <status>start</status>
  </vm>
</action>
" \
"${oe_url}/vms/${s_vm_id}/start" -o ${f_xml}

    check_fault ${f_xml}
    [ ${DEBUG} -eq 0 ] && rm -fv ${f_xml}
}

## 停止 vm
function vm_stop() {
    local s_vm_name="$1"
    vm_uuid ${s_vm_name}
    local f_xml="${s_vm_name}.stop.xml"
    
    ${curl_opts} \
-H "Content-Type: application/xml" \
-u "${oe_user}:${oe_password}" \
-d "
<action>
  <vm>
    <status>stop</status>
  </vm>
</action>
" \
"${oe_url}/vms/${s_vm_id}/stop" -o ${f_xml}

    check_fault ${f_xml}
    [ ${DEBUG} -eq 0 ] && rm -fv ${f_xml}
}

## 删除 vm
function vm_delete() {
    local s_vm_name="$1"
    vm_uuid ${s_vm_name}
    local f_xml="${s_vm_name}.delete.xml"
    
    ${curl_opts} \
-u "${oe_user}:${oe_password}" \
-X DELETE \
"${oe_url}/vms/${s_vm_id}" -o ${f_xml}

    check_fault ${f_xml}
    [ ${DEBUG} -eq 0 ] && rm -fv ${f_xml}
}

## 只运行一次，使用固定的模版配置 cloud-init
function vm_runonce() {
    local s_vm_name="$1"
    vm_uuid ${s_vm_name}
    local f_xml="${s_vm_name}.runonce.xml"
    
    local s_vm_password="$2"
    local s_vm_ip="$3"
    local s_vm_netmask="$4"
    local s_vm_gateway="$5"
    local s_vm_dns="$6"

    local tpl_cloud_init="
<action>
<use_cloud_init>true</use_cloud_init>
<vm>
    <initialization>
        <cloud_init>
            <host>
                <address>${s_vm_name}</address>
            </host>
            <regenerate_ssh_keys>true</regenerate_ssh_keys>
            <users>
                <user>
                    <user_name>root</user_name>
                    <password>${s_vm_password}</password>
                </user>
            </users>
            <network_configuration>
                <nics>
                    <nic>
                        <name>eth0</name>
                        <boot_protocol>DHCP</boot_protocol>
                        <on_boot>false</on_boot>
                    </nic>
                    <nic>
                        <name>eth1</name>
                        <boot_protocol>static</boot_protocol>
                        <network>
                            <ip address=\"${s_vm_ip}\" netmask=\"${s_vm_netmask}\" gateway=\"${s_vm_gateway}\" />
                        </network>
                        <on_boot>true</on_boot>
                    </nic>
                </nics>
                <dns>
                    <servers>
                        <host>
                            <address>${s_vm_dns}</address>
                        </host>
                    </servers>
                </dns>
            </network_configuration>
            <files>
                <file>
                    <name>post-init</name>
                    <content>
runcmd:
- curl http://192.168.20.102/ovirt/test.sh |bash -
                    </content>
                    <type>plaintext</type>
                </file>
            </files>
        </cloud_init>
    </initialization>
</vm>
</action>
"
    # 仅用作调试，输出 cloud-init 的 xml 文件
    local f_xml_init="${s_vm_name}.cloud-init.xml"
    [ ${DEBUG} -eq 1 ] && echo "${tpl_cloud_init}" >${f_xml_init}

    ${curl_opts} \
-H "Content-Type: application/xml" \
-u "${oe_user}:${oe_password}" \
-d "${tpl_cloud_init}" \
"${oe_url}/vms/${s_vm_id}/start" -o ${f_xml}

    check_fault ${f_xml}
    [ ${DEBUG} -eq 0 ] && rm -fv ${f_xml}
}

## 只运行一次，使用指定的模版
function vm_runonce_tpl() {
    local s_vm_name="$1"
    vm_uuid ${s_vm_name}
    local f_xml="${s_vm_name}.runonce.xml"
    local tpl_cloud_init="`cat $2`"


    ${curl_opts} \
-H "Content-Type: application/xml" \
-u "${oe_user}:${oe_password}" \
-d "${tpl_cloud_init}" \
"${oe_url}/vms/${s_vm_id}/start" -o ${f_xml}

    check_fault ${f_xml}
}

## 从模版创建 VM ，不是(Clone/Independent)，而是(Thin/Dependent)
function vm_create_from_tpl() {
    local s_vm_name="$1"
    local s_tpl_name=$2
    local s_cluster_name=$3
    
    local f_xml="${s_vm_name}.create.xml"

    ${curl_opts} \
-H "Content-Type: application/xml" \
-u "${oe_user}:${oe_password}" \
-d "
<vm>
  <name>${s_vm_name}</name>
  <cluster><name>${s_cluster_name}</name></cluster>
  <template><name>${s_tpl_name}</name></template>
</vm>
" \
"${oe_url}/vms" -o ${f_xml}

    check_fault ${f_xml}
    [ ${DEBUG} -eq 0 ] && rm -fv ${f_xml}
}

## Usage
function usage() {
    echo "

usage: $0 [list|start|stop|delete|create|init|init-tpl] vm_name

    列出所有的VM：              list
    启动VM：                    start [vm_name]
    停止VM：                    stop [vm_name]
    删除VM：                    delete [vm_name]
    创建VM：                    create [vm_name template cluster]
    只运行一次：                init [vm_name root_password vm_ip vm_netmask vm_gateway vm_dns]
    只运行一次（指定模版）：    init-tpl [vm_name template-file]

"
    exit 1
}

## Main
s_action=$1
s_vm_name=$2
## $3 to $7 预留给 vm_runonce_tpl

case ${s_action} in
    list)
        vm_list
        grep -E '<(name|comment|state)>' vms.xml |grep -vE '(Etc}|GMT|internal)' |sed 's/ //g' |sed -E 's/<\/(name|comment|state)>//g' |sed 's/<name>/--------\nname\t: /g' |sed 's/<//g' |sed 's/>/\t: /g'
        ;;
    start|stop)
        vm_${s_action} ${s_vm_name}
        vm_state ${s_vm_name}
        ;;
    delete)
        vm_${s_action} ${s_vm_name}
        ;;
    create)
        vm_create_from_tpl ${s_vm_name} 'tpl-m1' 'C01'
        vm_state ${s_vm_name}
        ;;
    init)
        if [ ! $# -eq 7 ]; then
            usage
        fi
        vm_runonce ${s_vm_name} $3 $4 $5 $6 $7
        vm_state ${s_vm_name}
        ;;
    init-tpl)
        if [ ! $# -eq 3 ]; then
            usage
        fi
        vm_runonce_tpl ${s_vm_name} $3
        vm_state ${s_vm_name}
        ;;
    *)
        usage
        ;;
esac        


