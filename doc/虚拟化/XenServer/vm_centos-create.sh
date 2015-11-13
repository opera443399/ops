#!/usr/bin/env bash
#

if [ "$#" -ne "7" ];then
    echo "$0: incorrect parameter!"
    echo "usage: $0 <hostname> <cpucount> <memsize /MB> <disksize /GB> <diskswapsize> <ipaddress> <gateway>"
    echo "example: $0 sz-loccal-vm-cms 2 2000 100GB 5GB 192.168.20.22 192.168.20.1"
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
WORKSPACE=$(pwd)
MACADDR=$($WORKSPACE/macgen.py)

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
sed -i '/IPV6/d' /mnt/$HOSTNAME/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/dhcp/none/' /mnt/$HOSTNAME/etc/sysconfig/network-scripts/ifcfg-eth0
echo "IPADDR=$IPADDR" >> /mnt/$HOSTNAME/etc/sysconfig/network-scripts/ifcfg-eth0
echo "NETMASK=255.255.255.0" >> /mnt/$HOSTNAME/etc/sysconfig/network-scripts/ifcfg-eth0
echo "GATEWAY=$GW" >> /mnt/$HOSTNAME/etc/sysconfig/network-scripts/ifcfg-eth0
umount /mnt/$HOSTNAME

# create pv config file
cat <<E_O_F >> /etc/xen/$HOSTNAME.cfg

kernel      = '/usr/local/lib/xen/boot/pv-grub-x86_64.gz'
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

vif = [ "bridge=ovsbr0, ip=$IPADDR, mac=$MACADDR" ]

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
