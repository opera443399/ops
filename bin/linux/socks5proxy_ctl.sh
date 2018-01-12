#!/bin/bash
#
#2018/1/12

# 本地代理的 IP+端口
s_local='127.0.0.1:8888'
# 远程服务器的 用户+IP
s_remote="username@your_remote_host"

function do_get(){
	echo "[+] 获取当前http_proxy/https_proxy指令的值来验证是否生效："
	echo "http_proxy=${http_proxy}"
	echo "https_proxy=${https_proxy}"
}

function do_status(){
        echo "[-] 获取当前 ssh 隧道 的状态："
	ps -ef |grep 'ssh -CN -f -D' |grep "${s_local} ${s_remote}"
	if [ $? -eq 1 ]; then
		echo '无'
		echo
		exit 1
	fi
}

function do_on(){
        echo "[+] 启用代理："
	ssh -CN -f -D ${s_local} ${s_remote}
	do_status
}

function do_off(){
        echo "[+] 关闭代理："
	do_status
	s_pid=$(ps -ef |grep 'ssh -CN -f -D' |grep "${s_local} ${s_remote}" |awk '{print $2}')
	kill ${s_pid}
        echo "[-] 检查进程是否关闭："
	ps -ef |grep 'ssh -CN -f -D' |grep "${s_local} ${s_remote}"
	[ $? -eq 1 ] && echo '已关闭'
}

function usage(){
	cat <<_EOF
######
###### 来，试试这个 ssh 代理脚本，快速帮你完成工作
######

USAGE:
        $0 [get|on|off|status]


#--------------- 使用方法1: 临时使用 ---------------#
### 在当前 shell 执行（其他已经打开的 shell 并不会立即生效）
export http_proxy=socks5://${s_local}
export https_proxy=socks5://${s_local}

### 取消proxy
export http_proxy=
export https_proxy=

#--------------- 使用方法2: 长期使用 ---------------#
### 2. 在配置文件中增加上述2个指令
/etc/profile （所有用户生效）
~/.bashrc （仅自己的账号生效）

配置文件更新后要使用 source 来直接使用，否则要重启后才能生效
source /etc/profile
or:
source ~/.bashrc

### 取消代理
注释掉增加的指令后再次 source 一下并执行：
unset http_proxy
unset https_proxy

_EOF
	exit 0
}


case $1 in
	get|on|off|status)
		do_$1
		;;
	*)
		usage
		;;
esac
