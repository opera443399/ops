#!/bin/bash
# ​OS安装完后，初始化系统。更新和安装部分包和epel源，禁用selinux，同步时间，设置utf-8，limits，profile的配置文件。
# 2015/07/14
 
yum -y update
yum -y groupinstall "Development Tools"
yum -y install lrzsz wget vim ntp

# 先同步一次时间，后续要通过局域网的ntp服务器来定时同步。
/usr/sbin/ntpdate stdtime.gov.hk

# CentOS 用户可以直接通过 yum install epel-release 安装并启用 EPEL 源。CentOS Extras 默认包含该包。 
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
yum makecache
 
 
# 禁用selinux
# modify /etc/sysconfig/selinux 
# to: SELINUX=disabled
# and reboot later.
setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
 
# utf-8
[ -f /etc/sysconfig/i18n.bak ] || cp -a /etc/sysconfig/i18n /etc/sysconfig/i18n.bak && \
echo 'LANG="en_US.UTF-8"' > /etc/sysconfig/i18n
 
 
# limits
sed -i 's/1024/65535/' /etc/security/limits.d/90-nproc.conf
 
cat <<_LIMIT >/etc/security/limits.d/my-limits.conf
*          soft    nofile    65535 
*          hard    nofile    65535
*          soft    core      unlimited
_LIMIT
 
# profile
cat <<_PROFILE >>/etc/profile
alias ls='ls --color=tty'
alias ll='ls -l --color=tty'
alias l.='ls -d .* --color=tty'
alias vi='vim'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias grep='grep --color'
alias pgrep='pgrep -l'
alias fgrep='fgrep --color'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'
 
export HISTTIMEFORMAT="%F %T "
export HISTFILESIZE=50000
export HISTSIZE=50000
 
_PROFILE
