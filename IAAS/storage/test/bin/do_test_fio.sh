#!/bin/bash
#
#2016/8/29
# 一个简单的测试示例
# yum install fio -y

test -d '/mnt/TEST_IOPS' || mkdir -p /mnt/TEST_IOPS
cd /mnt/TEST_IOPS
echo >run.log

do_test() {
    echo "[+] START at: `date +%F_%T`" >>run.log
    fio --direct=1 --ioengine=libaio --filename=/mnt/TEST_IOPS/tttt --rw=rw --bs=4k --size=20G --runtime=3600 --iodepth=8 --name=4K.rw
    echo "[-] STOPPED at: `date +%F_%T`"  >>run.log
}

while true
do
    rm -f /mnt/TEST_IOPS/tttt
    do_test
done
