#!/bin/bash
# 2015/11/6
# cache rpms from ceph to localhost
# for:
#   - ceph.repo

function validate_wget() {
    cd $1
    for f_rpm in `ls .`; do 
        echo "[validate] ${f_rpm}"
        wget -c $2/"${f_rpm}"
    done
}

function update_repo() {
    d_dest='/var/www/html/ceph/rpm-giant/el6'
    mkdir ${d_dest}/{x86_64,noarch,SRPMS} -p
############################ ceph rpms ###############################
    cd ${d_dest}/x86_64
    wget --execute robots=off -nc -nd -r -l1 -A '*.rpm' -R 'ceph-debuginfo*.rpm' http://download.ceph.com/rpm-giant/el6/x86_64
    validate_wget ${d_dest}/x86_64 http://download.ceph.com/rpm-giant/el6/x86_64
    
    cd ${d_dest}/noarch
    wget --execute robots=off -nc -nd -r -l1 -A '*.rpm' http://download.ceph.com/rpm-giant/el6/noarch
    validate_wget ${d_dest}/noarch http://download.ceph.com/rpm-giant/el6/noarch
    
    cd ${d_dest}/SRPMS
    wget --execute robots=off -nc -nd -r -l1 -A '*.rpm' http://download.ceph.com/rpm-giant/el6/SRPMS
    validate_wget ${d_dest}/SRPMS http://download.ceph.com/rpm-giant/el6/SRPMS
############################ createrepo ###############################
    cd ${d_dest}/x86_64
    /usr/bin/createrepo .
    cd ${d_dest}/noarch
    /usr/bin/createrepo .
    cd ${d_dest}/SRPMS
    /usr/bin/createrepo .

    exit 0
}


############################ ceph.repo ###############################
function file_repo() {
    cat <<'_EOF' >ceph.repo
[Ceph]
name=Ceph packages for $basearch
baseurl=http://ceph.com/rpm-giant/el6/$basearch
baseurl=http://mirrors.office.test/ceph/rpm-giant/el6/$basearch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=http://mirrors.office.test/ceph/release.asc
priority=1

[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://ceph.com/rpm-giant/el6/noarch
baseurl=http://mirrors.office.test/ceph/rpm-giant/el6/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=http://mirrors.office.test/ceph/release.asc
priority=1

[ceph-source]
name=Ceph source packages
baseurl=http://ceph.com/rpm-giant/el6/SRPMS
baseurl=http://mirrors.office.test/ceph/rpm-giant/el6/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=http://mirrors.office.test/ceph/release.asc
priority=1

_EOF

}

function usage() {
    echo "$0 file|update"
    exit 0
}

case $1 in
    file|update)
        $1_repo
        ;;
    *)
        usage
        ;;
esac
