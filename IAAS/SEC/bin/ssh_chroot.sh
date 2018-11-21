#!/bin/bash
#PC
#20170724
# on centos7

jail_home='/home/jail_root'
cmd_lists='bash cat cd date df id ls mkdir ssh touch vim whoami'
chroot_group_name='ssh_chroot_users'
chroot_group_id=8888


function print_line(){
    echo -e "\n______________________________ $1 ____________________________\n"
}
    
function do_init(){
    mkdir -v ${jail_home}
    cd ${jail_home}
    mkdir -v dev etc home lib64 usr

    print_line 'dev'
    cd "${jail_home}/dev"
    mknod -m 666 null c 1 3
    mknod -m 666 tty c 5 0
    mknod -m 666 zero c 1 5
    mknod -m 666 random c 1 8


    print_line 'lib64, usr/bin'
    cd "${jail_home}"
    mkdir usr/bin
    for cmd_name in ${cmd_lists}; do
        whereis ${cmd_name} |awk '{print $2}' |xargs -i cp -av {} ${jail_home}/usr/bin/
        ldd usr/bin/${cmd_name} |grep / |awk '{print $3}' |grep -v '^$' |xargs -i cp -v {} ${jail_home}/lib64/
        ldd usr/bin/${cmd_name} |sed 's#\t##' |grep '^/' |awk '{print $1}' |xargs -i cp -v {} ${jail_home}/lib64/
    done
    # for cmd: id
    cp -fv /lib64/libnss_files.so.2 ${jail_home}/lib64/
    # ln -s
    ln -s usr/bin bin
    ln -s usr/bin/bash usr/bin/sh
    ln -s usr/bin/vim usr/bin/vi
    
    print_line 'etc, home'
    cd "${jail_home}"
    groupadd --gid ${chroot_group_id} ${chroot_group_name}

    grep ssh_chroot_users /etc/ssh/sshd_config || \
        cat <<_EOF >>/etc/ssh/sshd_config
# -ssh chroot configuration -
Match Group ssh_chroot_users
ChrootDirectory ${jail_home}

_EOF

    systemctl restart sshd

    cp -av /etc/{passwd,group,nsswitch.conf} etc/
    cp -av /etc/{bashrc,profile} etc/
    echo >etc/passwd
    echo >etc/group
}


function jailed_user(){
    user_name=$1

    #tips: useradd user_name && passwd user_name
    print_line 'jailed user'
    cd "${jail_home}"
    cp -av /home/${user_name} ${jail_home}/home/
    usermod -g ssh_chroot_users ${user_name}
    grep ${user_name} /etc/passwd >>${jail_home}/etc/passwd
    grep ${user_name} /etc/group >>${jail_home}/etc/group
}


case $1 in
    init)
        do_init
        ;;
    jail)
        shift
        jailed_user $@
        ;;
    *)
        echo "$0 [init|jail] user"
esac
