#!/bin/bash
#
#2017/12/1

#local proxy endpoint
s_local='127.0.0.1:8888'
#your remote host
s_remote="username@your_remote_host"

function do_get(){
	echo "[+] GET proxy"
	echo "http_proxy=${http_proxy}"
	echo "https_proxy=${https_proxy}"
}

function do_status(){
	echo "[-] current tunnel:"
	ps -ef |grep 'ssh -CN -f -D' |grep "${s_local} ${s_remote}"
	if [ $? -eq 1 ]; then
		echo 'NOT FOUND'
		echo
		exit 1
	fi
}

function do_on(){
  echo "[+] TURN ON proxy"
	ssh -CN -f -D ${s_local} ${s_remote}
	do_status
}

function do_off(){
  echo "[+] TURN OFF proxy"
	do_status
	s_pid=$(ps -ef |grep 'ssh -CN -f -D' |grep "${s_local} ${s_remote}" |awk '{print $2}')
	kill ${s_pid}
  echo "[-] check:"
	ps -ef |grep 'ssh -CN -f -D' |grep "${s_local} ${s_remote}"
	[ $? -eq 1 ] && echo -n 'PASS'
}

function usage(){
	cat <<_EOF

http/https proxy quickfix

$0 get|on|off|status

how to use:

export http_proxy=socks5://${s_local}
export https_proxy=socks5://${s_local}


how to reset:

export http_proxy=
export https_proxy=


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
