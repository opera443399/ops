linux bash shell 三言两语
2018/7/13

linux bash shell的使用博大精深，，本人梳理基础知识，整理一下简单的用法，细节请根据需求自行研究。


1. 计算
# echo $((1+2))
3
# echo $((1+2+3))
6
# echo 3+2+5 |bc
10



2. if的用法
if [ $i -eq 0 ]; then
    xxx
else
    xxx
fi

注意下面这2种判断方式：
1）test， && 和 || 的用法
[root@tvm01 ~]# a=3
[root@tvm01 ~]# test $a -eq 3 && echo 'a' || echo 'b'
a
[root@tvm01 ~]# test $a -eq 4 && echo 'a' || echo 'b'
b
[root@tvm01 ~]# test $a -eq 4 && echo 'a' || echo 'b' && echo 'c'
b
c
[root@tvm01 ~]# test $a -eq 3 && echo 'a' || echo 'b' && echo 'c'
a
c
2）不加if，也不用 test
[ -d '/tmp/aaa' ] || mkdir -p /tmp/aaa

3）整数比较：
-eq 等于,如:if [ "$a" -eq "$b" ]
-ne 不等于,如:if [ "$a" -ne "$b" ]
-gt 大于,如:if [ "$a" -gt "$b" ]
-ge 大于等于,如:if [ "$a" -ge "$b" ]
-lt 小于,如:if [ "$a" -lt "$b" ]
-le 小于等于,如:if [ "$a" -le "$b" ]
<   小于(需要双括号),如:(("$a" < "$b"))
<=  小于等于(需要双括号),如:(("$a" <= "$b"))
>   大于(需要双括号),如:(("$a" > "$b"))
>=  大于等于(需要双括号),如:(("$a" >= "$b"))

4）字符串比较：
通常是这样做的：
if [ X"$test" = X"test" ]

= 等于,如:if [ "$a" = "$b" ]

-d 目录
-e 存在
-f 文件
-n 非空字符串
-z 空字符串


5）来点儿复杂的：
have_program() {
    hash "$1" >/dev/null 2>&1
}
# 下面if语句中调用的have_program若为真，则判断为假，反之则进入if语句执行错误提示
dep_check() {
    if ! have_program "$1"; then
        exit_message "'${1}' command not found. Please install or add it to your PATH and try again."
    fi
}
# 判断用户的权限
if [ `id -u` -ne 0 ]; then
    echo "You must run this script as root."
    if [ -x /usr/bin/sudo ]; then
        echo "Try running 'sudo ${0}'."
    fi
    exit 1
fi >&2
# 判断几个命令是否可用
echo "Checking for required packages..."
for pkg in rpm yum python curl; do
    dep_check "$pkg"
done



3. for的用法
### exp1
# cat /tmp/t.sh
s=(
aaa
bbb
ccc
)
for i in ${s[@]}; do
  echo "[I] ---> ${i}"
done

# sh /tmp/t.log
[I] ---> aaa
[I] ---> bbb
[I] ---> ccc

### exp2
array1=("d.com" "e.com" "f.com")
len=${#array1[@]}

for ((i=0;i<$len;i++))
do
    echo ${array1[$i]}
done

### exp3
for a in $(seq 1 100);do
    echo $a
    sleep 1s
done


4. case的用法
case $1 in
    start|stop|reload)
        $1
        ;;
    *)
        echo "Usage: $0 [start|stop|reload]"
        ;;
esac


5. while的用法
while true
do
    echo "abc"
    read -p "请输入: " abc
    ddd="$abc"
    if [ ${#ddd} -ne 5 ]; then
        echo "请重新输入！！！"
    else
        break
    fi
done

和case结合的用法:
while getopts "h" option; do
    case "$option" in
        h) usage ;;
        *) usage ;;
    esac
done

和read结合的用法:
从文件中逐行读入内容，拼接字符串
s='\n\n'
while read line
do
    s="${s}${line}\n"
done </tmp/a.txt
echo -e $s


和read ignore结合的用法：
# echo 'a b c d e' |while read ignore args; do echo $args; done
b c d e
# echo 'a b c d e' |while read ignore ignore args; do echo $args; done
c d e
# cat /etc/init.d/network |grep static-routes --color -A 3
        # Add non interface-specific static-routes.
        if [ -f /etc/sysconfig/static-routes ]; then
           grep "^any" /etc/sysconfig/static-routes | while read ignore args ; do
              /sbin/route add -$args
           done
        fi
其实，这里的ignore也是一个变量：
# echo 'a b c d e' |while read ignore args; do echo "$ignore $args"; done
a b c d e
# echo 'a b c d e' |while read ignore ignore args; do echo "$ignore $args"; done
b c d e

read后可以跟多个变量，依次接收传递过来的值。

6. 参数
[root@test t]# cat t.sh
#!/bin/bash
#
#  $0 是这个bash文件的名称；
#  $1 是第1个参数；
#  $? 是上一指令的返回值；
#  $* 是该脚本调用的所有参数；
#  $@ 基本与上面的$*相同。区别是：
#      $* 返回的是一个字符串，字符串中用空格分隔开，而 $@ 则返回多个字符串；
#  $# 是所有位置参数的个数；
#  $$ 是返回上一个指令对应的pid
#
ab=($(ls))
echo '${ab[@] -> '${ab[@]}
echo '${#ab[@]} -> '${#ab[@]}

echo '$0 -> '$0
echo '$1 -> '$1
echo '$2 -> '$2
echo '$? -> '$?
echo '$* -> '$*
echo '$@ -> '$@
echo '$# -> '$#
echo '$$ -> '$$
[root@test t]# sh t.sh zzz yyy xxx www -h
${ab[@] -> set_color.sh t.sh
${#ab[@]} -> 2
$0 -> t.sh
$1 -> zzz
$2 -> yyy
$? -> 0
$* -> zzz yyy xxx www -h
$@ -> zzz yyy xxx www -h
$# -> 5
$$ -> 30383


7. 正则
 正则表达式匹配"=~"
 [[ $XX =~ ^$XXX ]]
The =~ Regular Expression matching operator within a double brackets test expression.

$ [[ "# test2" =~ ^# ]] && echo yes || echo no
yes


8. 截取字符串

假设有：
f="/a/b/c/d/e.name.ext"

则：
# basename $f
e.name.ext
# dirname $f
/a/b/c/d

特殊用法：利用${}中的#,%,*来输出指定的内容
1）去掉第一个/，以及左边的字符串
# echo ${f#*/}
a/b/c/d/e.name.ext

2）去掉最后1个/，以及左边的字符串
# echo ${f##*/}
e.name.ext

3）去掉最后一个/，以及右边的字符串
# echo ${f%/*}
/a/b/c/d

4）去掉第一个/，以及右边的字符串
# echo ${f%%/*}
（空）

上面，是根据“/”来做分割，也可以用“."来分隔，不妨一试。
# echo ${f#*.}
name.ext
# echo ${f##*.}
ext
# echo ${f%.*}
/a/b/c/d/e.name
# echo ${f%%.*}
/a/b/c/d/e


9. 脚本放入后台，输出到日志
sh test.sh >1.log 2>&1 &
sh test.sh >/dev/null 2>&1 &
这里需要理解几个小东西的作用：
/dev/null   理解成空设备，这是一个特殊的文件，这里的作用是丢弃输出的内容
2>&1        0 输入  1 输出  2 错误 这里是将2重定向到1
&           将test.sh放入后台执行，请思考，还有其他的什么方式也可以将程序放入后台？


10. 管道
通过“|” 把输出导入到另一个程序的输入中去处理，例如：
echo 'abc, def' |cut -d ',' -f 1


11. 命令跟踪调试
sh -x test.sh


12. 快捷键
Ctrl + a 切换到命令行开始
Ctrl + b - Move back a char
Ctrl + c 终止命令
Ctrl + d 退出shell,logout
Ctrl + e 切换到命令行末尾
Ctrl + l 清除屏幕内容
Ctrl + k 剪切清除光标之后的内容
ctrl + q 恢复刷屏
Ctrl + r 在历史命令中查找
ctrl + s 可用来停留在当前
Ctrl + u 清除剪切光标之前的内容
Ctrl + y 粘贴刚才所删除的字符
Ctrl + z 转入后台运行
!! 重复执行最后一条命令
↑（Ctrl+p） 显示上一条命令
↓（Ctrl+n） 显示下一条命令
!$ 显示系统最近的一条参数


13. 在shell中调用python的方法
# python <<'_EOF'
import sys

print(sys.version)
_EOF

2.6.6 (r266:84292, Jan 22 2014, 09:42:36)
[GCC 4.4.7 20120313 (Red Hat 4.4.7-4)]

shell传递中文到python出现异常时：
export LANG="en_US.UTF-8";
/usr/local/bin/python3  xxx.py


14. 创建临时目录的方法
tempdir=`mktemp -d`
cd "$tempdir"

15. 一个简单的密码生成方法
pw=`date +%N|cut -c1-8`
man date查看：
%N     nanoseconds (000000000..999999999)
man cut查看：
?-c, --characters=LIST
              select only these characters

16. 简单ping一下C段的IP
subnet=192.168.1; for i in {1..254};
do
    ping -c 1 -w 1 ${subnet}.${i} >/dev/null && echo "${subnet}.${i}: up" || echo "${subnet}.${i}: down";
done

17. 字符串反转
# echo 'abcde' |rev
edcba

18. crontab的用法
1）格式不清楚可以这样：
cat /etc/crontab 或者 man 5 crontab

2）注意：用户权限，是否需要特殊的环境变量。
3）注意：特殊符合，例如：% 在 crontab 中是特殊的意义（换行）
Percent-signs (%) in the command, unless escaped with backslash (\), will be changed into new-line characters, and all data after the first % will be sent to the command as standard input.
举例：
【错误】
0 2 * * * echo 'test' >/tmp/test_$(date +%Y%m%d).log 2>&1 &
【正确】
0 2 * * * echo 'test' >/tmp/test_$(date +\%Y\%m\%d).log 2>&1 &


19. 在 shell 中使用 Here Document 的使用注意
常见写法，可以使用变量：
test=$(blkid /dev/vg0/lv01 |cut -d'"' -f2)
cat <<_EOF >>/etc/fstab
UUID=$test /data                   xfs     defaults        0 0
_EOF

换一种，则无法使用变量：
cat <<'_EOF' >>/etc/fstab
UUID=$test /data                   xfs     defaults        0 0
_EOF


20. 测试主机内存占用状况（模拟分配最少 1 GiB 内存）
python -c "import time;d='a'*1024*10**6;time.sleep(3600)" &


21. 排序的疑问
[root@tvm01 ~]# cat a.test
a
b
c
d
e
a
b
c
d
e
1
2
3
4
5
1
1
2
2
3
3
[root@tvm01 ~]# cat a.test |uniq |sort
1
1
2
2
3
3
4
5
a
a
b
b
c
c
d
d
e
e
[root@tvm01 ~]# cat a.test |sort |uniq |sort
1
2
3
4
5
a
b
c
d
e
上述2者的效果不一样，为何？
原因：uniq命令隔行重复是无效的，针对这种情况，需要先用sort排序再uniq。


22、临时启用一个端口来测试
python -m SimpleHTTPServer 8081
这个简单的http服务器，还可以当作ftp用


23、示例随机字符的生成：得到一个MAC地址的3种方式
echo "AA:BB:`dd if=/dev/urandom count=1 2>/dev/null |md5sum |sed -e 's/^\(..\)\(..\)\(..\)\(..\).*$/\1:\2:\3:\4/'`"
echo "AA:BB:`for i in {1..4};do printf "%0.2X:" $[ $RANDOM % 0x100 ]; done |sed 's/:$/\n/'`"
echo "AA:BB:`od /dev/urandom -w4 -tx1 -An |sed -e 's/ //' -e 's/ /:/g' |head -n 1`"



24、在shell中使用递归的一个小示例
需求：下载一个小说的文字内容。
~]# cat test.sh
#!/bin/bash
#

do_rewrite() {
    ff=$1
    echo "[*] Convert -> ${ff}"
    wget -q http://www.zanghaihuawang.com/laojiumen/${ff}.html -O old/${ff}.html
    grep 'h2' old/${ff}.html >/dev/null
    if [ $? -eq 1 ]; then
        echo '[E] empty file.'
        exit 1
    else
        cat <<'_EOF' >new/${ff}.html
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
</head>
<body>
_EOF
        sed -n '/<h2>/,/\[Enter\]/p' old/${ff}.html |sed 's/\/laojiumen\///' >>new/${ff}.html
        cat <<'_EOF' >>new/${ff}.html
</body>
</html>
_EOF
        f_next=$(cat new/${ff}.html |grep 'pager_next' |grep -Eo '[0-9]+')
        if [ -z ${f_next} ]; then
            echo '[E] next file not found.'
            exit 2
        else
            do_rewrite ${f_next}
        fi
    fi
}

do_gb2312_to_utf8() {
    #yum -y groupinstall "Development Tools" && wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz && tar zxvf libiconv-1.14.tar.gz && cd libiconv-1.14 && ./configure && make && make install
    for i in `ls new/`; do iconv -c -f gb2312 -t utf-8 test/$i >new_utf8/$i;done
}

mkdir -p old new
do_rewrite $1


25、set的用途
1）设置参数
在脚本中：
# cat t.sh
set z1 y1 x1 w1
echo '$1 -> '$1
echo '$2 -> '$2
echo '$@ -> '$@
echo '$# -> '$#

# sh t.sh z y x w
$1 -> z1
$2 -> y1
$@ -> z1 y1 x1 w1
$# -> 4

在命令行：
[root@ttt ~]# set z y x w
[root@ttt ~]# echo $#
4
[root@ttt ~]# echo $@
z y x w


2）设置选项
set -e ：命令执行结果不为0，则退出
set -x ：调试输出

其他请参考man手册


26、如何审计操作
提供一些思路：
script
PROMPT_COMMAND
用法，请搜索相关主题。



27、查看内存占用：
ps -u appuser  -wo rss=,comm= --sort -rss | while read -r rss comm ; do echo $((rss/1024))"MB -" $comm; done |head -n 10


28、如何使用!$
[root@test ~]# ls /tmp/
cvm_init.log  net_affinity.log  sagent.pid  setRps.log
[root@test ~]# echo !$
echo /tmp/
/tmp/

显然，要调用上一条指令的最后一个参数，不妨试试 !$


28、查看 ip=192.168.200.201 监听的端口（8300-8599这个范围的）：
ss -ant |awk '$4~/192.168.200.201:8[3-5]/ {print $0}'


29、防火墙常用操作
放行端口
iptables -A INPUT -s 1.2.3.4/32 -p tcp -m tcp --dport 8080 -j ACCEPT
iptables -A INPUT -s 1.2.3.4/32 -p tcp -m tcp --dport 4000:4099 -j DROP

端口转发
iptables -t nat -A PREROUTING -d 服务器外网IP/32 -p tcp -m tcp --dport 8080 -j DNAT --to-destination 服务器内网IP
iptables -t nat -A POSTROUTING -d 服务器内网IP/32 -p tcp -m tcp --dport 8080 -o eth0 -j MASQUERADE


30、查看和清理指定用户下的进程和线程
ps -U username
ps -U username -L
ps -U username |awk '{print $1}' |grep -Eo '[0-9]+' |xargs -i kill {}


31、$'string' 的用法
参考：
http://www.gnu.org/software/bash/manual/html_node/ANSI_002dC-Quoting.html
https://stackoverflow.com/questions/18626209/bash-syntax-error-near-unexpected-token

是不是在 init.d 的脚本中常看到这样一段：
echo $"Usage: xxx"

这个 dollar sign $ 是啥意思呢？

Words of the form $'string' are treated specially. The word expands to string, with backslash-escaped characters replaced as specified by the ANSI C standard.

就是说，字符串前边有个美元符号，意味着可以使用转义符。


32、base64编码解码
echo -n "foo" |base64
base64 -d <<< "Zm9v"
while read line; do cnt=$(echo $line |wc -c); [ $cnt -gt 1000 ] && continue; echo $line;echo -e '\n----->\n';echo -n $line |base64 -d; echo -e '\n\n'; done<1.txt


33、对比 here document 还有一种 here string 的写法
<< denotes a here document
<<< denotes a here string

$ cat <<< 'hi there'
hi there

read first second <<< "hello world"
echo $second $first


34、进制转换
将 16 进制 -> 10 进制
[root@dev8 run]# echo $((0x13b))
315

将 10 进制 -> 16 进制
[root@dev8 run]# printf "0x%x\n" 315
0x13b
或者另一个方法：
[root@dev8 run]# echo "0x$(echo "obase=16;315"|bc |tr 'A-Z' 'a-z')"
0x13b



35、在 bash 中使用代理
先使用 ssh 转发一个 socks 端口出来：
$ ssh -CN -f -D 127.0.0.1:8888 user@remote_host
参数含义：（主要使用 -D 来转发）
-C      Requests compression of all data
-N      Do not execute a remote command.  This is useful for just forwarding ports.
-f      Requests ssh to go to background just before command execution.
-D [bind_address:]port
             Specifies a local ``dynamic'' application-level port forwarding.

以 socks5 代理为例：
export http_proxy=socks5://127.0.0.1:8888
export https_proxy=socks5://127.0.0.1:8888

注意，上述 export 的变量，如果切换来 shell 则会失效，不过这也难不倒熟悉 bash 的童鞋，这里记录下来，仅作为提醒。
