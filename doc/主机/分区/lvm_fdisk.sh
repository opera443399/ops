#!/bin/bash
#
# 2015/4/30
# 创建和删除lvm分区的一个示例

function part_lvm() {
  echo -e "\033[1;40;31m[+] 使用fdisk创建分区\033[0m"
  echo -e "\033[40;32m开始操作：\033[40;37m"
  fdisk $1 <<_EOF
n
p
1


t
8e
p
w
_EOF
  echo
  echo -e "\033[40;32m完成！\033[40;37m"
  echo -e "\033[1;40;31m[-] 已经创建分区：${1}1\033[0m"
}

function part_rm() {
  echo -e "\033[1;40;31m[+] 使用fdisk删除分区\033[0m"
  echo -e "\033[40;32m开始操作：\033[40;37m"
  count=$(fdisk -l /dev/sdb |grep dev |grep -v Disk |wc -l)
  if [ $count -lt 2 ]; then
    fdisk $1 <<_EOF
d
p
w
_EOF
    echo
    echo -e "\033[40;32m完成！\033[40;37m"
    echo -e "\033[1;40;31m[-] 已经删除分区：${1}1\033[0m"
    echo
  else
    echo -e "\033[1;40;31m[-] 这个磁盘有多个分区，请先检查确认！\033[0m"
  fi
}

function usage() {
  cat <<_EOF

usage: $0 type device

$0 lvm /dev/sdb
$0 rm /dev/sdb

_EOF
}

case $1 in
  lvm|rm)
    part_$1 $2
    ;;
  *)
    usage
    ;;
esac
