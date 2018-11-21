# kickstart template for Fedora 8 and later.
# (includes %end blocks)
# do not use with earlier distros

#platform=x86, AMD64, or Intel EM64T
# System authorization information
auth  --useshadow  --enablemd5
# System bootloader configuration
bootloader --location=mbr
# Partition clearing information
clearpart --all --initlabel
# Use text mode install
text
# Firewall configuration
firewall --enabled
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US.UTF-8
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza
# Network information
$SNIPPET('network_config')
# Reboot after installation
reboot

#Root password
rootpw --iscrypted $default_password_crypted
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone  Asia/Shanghai
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr
# Allow anaconda to partition the system as needed
#autopart
part /boot --bytes-per-inode=4096 --fstype="ext4" --size=200 --ondisk=sda
part swap --bytes-per-inode=4096 --fstype="swap" --size=4096 --ondisk=sda
part / --bytes-per-inode=4096 --fstype="ext4" --size=1 --grow --ondisk=sda
part /data --bytes-per-inode=4096 --fstype="ext4" --size=1 --grow --ondisk=sdb


%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%packages
$SNIPPET('func_install_if_enabled')
@Base
@Development Tools
@Chinese-Support
ntp
lrzsz
git
%end

%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end

%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')

### repo ###
#
mv /etc/yum.repos.d/*.repo /tmp/ \
&& wget http://mirrors.office.test/local-office.repo -O /etc/yum.repos.d/local-office.repo \
&& yum clean all \
&& yum makecache

### ssh config ###
#
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.old \
&& cat <<"_EOF" >/etc/ssh/sshd_config
\# added by cobbler
Port 22
Protocol 2
SyslogFacility AUTHPRIV
\#PasswordAuthentication no
\#PermitRootLogin no
ChallengeResponseAuthentication no
GSSAPIAuthentication no
GSSAPICleanupCredentials no
UsePAM yes
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS
X11Forwarding yes
UseDNS no
Subsystem       sftp    /usr/libexec/openssh/sftp-server
_EOF

### datetime and crontab ###
#
ntpdate ntp.office.test
cat <<"_EOF" >/var/spool/cron/root
\# [daily]
\# added by cobbler
*/20 * * * * /usr/sbin/ntpdate ntp.office.test >/dev/null 2>&1 &
_EOF

### network ###
#
f_ifdev=`ip a |grep global |awk '{print \$NF}'`
f_ip=`ip a |grep global |cut -d '/' -f 1 |awk '{print \$NF}'`
f_mask=`ip a |grep global |cut -d '/' -f 2 |awk '{print \$1}'`
f_gw=`route -n |grep UG |awk '{print \$2}'`
f_dns=`cat /etc/resolv.conf |grep name |awk '{print $2}'`
cat <<_EOF >"/etc/sysconfig/network-scripts/ifcfg-\${f_ifdev}"
DEVICE=\${f_ifdev}
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=none
IPADDR=\${f_ip}
PREFIX=\${f_mask}
GATEWAY=\${f_gw}
DNS1=\${f_dns}
_EOF

### hostname ###
f_id=`echo \${f_ip} |awk -F '.' '{print "tvm-"\$3"-"\$4}'`
hostname \${f_id}

cat <<_EOF >/etc/sysconfig/network
NETWORKING=yes
HOSTNAME=\${f_id}
_EOF

### salt-minion ###
#
salt_m="salt-m.office.test"
yum install salt-minion -y

cp -a /etc/salt/minion /etc/salt/minion.bak
cat <<_EOF >/etc/salt/minion
master: \${salt_m}
id: \$(hostname)
_EOF


# Start final steps
$SNIPPET('kickstart_done')
# End final steps
%end
