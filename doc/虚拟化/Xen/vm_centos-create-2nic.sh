#!/usr/bin/env bash
#

if [ "$#" -ne "8" ];then
    echo "$0: incorrect parameter!"
    echo "usage: $0 <hostname> <cpucount> <memsize /MB> <disksize /GB> <diskswapsize> <ipaddress> <gateway> <ipaddress2>"
    echo "example: $0 test-vm22 2 2000 100GB 5GB 10.50.200.22 10.50.200.1 10.50.205.22 "
    exit 1
else
    set -e
fi

# declare variable
HOSTNAME=$1
CPUCOUNT=$2
MEMSIZE=$3
DISKSIZE=$4
SWAPSIZE=$5
IPADDR=$6
GW=$7
IPADDR2=$8
WORKSPACE=$(pwd)
MACADDR=$($WORKSPACE/macgen.py)
MACADDR2=$($WORKSPACE/macgen.py)

# create lv
lvcreate -L $DISKSIZE -n "$HOSTNAME-disk" vg0
lvcreate -L $SWAPSIZE -n "$HOSTNAME-swap" vg0

# format lv 
mkfs.ext4 /dev/vg0/$HOSTNAME-disk
mkswap -f /dev/vg0/$HOSTNAME-swap

# configure vm
mkdir /mnt/$HOSTNAME
mount -t ext4 /dev/vg0/$HOSTNAME-disk /mnt/$HOSTNAME

tar zxf $WORKSPACE/Centos6-5.tgz -C /mnt/$HOSTNAME/

sed -i "/HOSTNAME=/c HOSTNAME=$HOSTNAME" /mnt/$HOSTNAME/etc/sysconfig/network
eth0="/mnt/$HOSTNAME/etc/sysconfig/network-scripts/ifcfg-eth0"
eth1="/mnt/$HOSTNAME/etc/sysconfig/network-scripts/ifcfg-eth1"

cat <<E_ETH_0 >> ${eth0}
DEVICE="eth0"
BOOTPROTO="none"
NM_CONTROLLED="yes"
ONBOOT="yes"
TYPE="Ethernet"
IPADDR=$IPADDR
NETMASK=255.255.255.0
GATEWAY=$GW
E_ETH_0

cat <<E_ETH_1 >> ${eth1}
DEVICE="eth1"
BOOTPROTO="none"
NM_CONTROLLED="yes"
ONBOOT="yes"
TYPE="Ethernet"
IPADDR=$IPADDR2
NETMASK=255.255.255.0
E_ETH_1


umount /mnt/$HOSTNAME

# create pv config file
cat <<E_O_F >> /etc/xen/$HOSTNAME.cfg

kernel      = '/usr/lib/xen/boot/pv-grub-x86_64.gz'
extra = "(hd0)/boot/grub/menu.lst"

memory = "$MEMSIZE"
maxmem = 10000
name = "$HOSTNAME"
vcpus = "$CPUCOUNT"
maxvcpus = 10

disk        = [
                "phy:/dev/vg0/$HOSTNAME-disk,xvda1,w",
                "phy:/dev/vg0/$HOSTNAME-swap,xvdb1,w"
              ]

#  Networking

vif = [ "bridge=xenbr1, ip=$IPADDR, mac=$MACADDR","bridge=xenbr2, ip=$IPADDR2, mac=$MACADDR2" ]

#  Behaviour

on_poweroff = 'destroy'
on_reboot   = 'restart'
on_crash    = 'restart'
E_O_F

# auto startup
if [ -d /etc/xen/auto ]; then
    ln -s /etc/xen/$HOSTNAME.cfg /etc/xen/auto/$HOSTNAME.cfg
else
    mkdir /etc/xen/auto
    ln -s /etc/xen/$HOSTNAME.cfg /etc/xen/auto/$HOSTNAME.cfg
fi

echo "VM $HOSTNAME create done!!!"
echo "startup command "
echo "xl create -c /etc/xen/$HOSTNAME.cfg"
echo "Enjoy !"
