#!/bin/bash
# 2015/12/28
# cache rpms from ovirt to localhost
# from: yum install http://resources.ovirt.org/pub/yum-repo/ovirt-release36.rpm
# for:
#   - ovirt-3.6.repo
#   - ovirt-3.6-dependencies.repo
# Supported Hosts
#    Fedora 21, 22
#    CentOS Linux 6.7 (3.5 only), 7.2
#    Red Hat Enterprise Linux 6.7 (3.5 only), 7.2
#    Scientific Linux 6.7 (3.5 only), 7.2
# so,, you also need ovirt-3.5.repo to install vdsm related rpms on OS version: el6
# or, cached el7 related rpms when you need to install vdsm on OS like centos7.

function validate_wget() {
    cd $1
    for f_rpm in `ls .`; do 
        echo "[validate] ${f_rpm}"
        wget -c $2/"${f_rpm}"
    done
}

function update_repo() {
    d_dest='/var/www/html/ovirt/ovirt-3.6/rpm'
    mkdir ${d_dest}/el6/{noarch,x86_64} -p
    mkdir ${d_dest}/dependencies/{jpackage,gluster,patternfly,others} -p


############################ ovirt ###############################
    cd ${d_dest}/el6/noarch
    wget --execute robots=off -nc -nd -r -l1 -A'*.rpm' http://resources.ovirt.org/pub/ovirt-3.6/rpm/el6/noarch
    validate_wget ${d_dest}/el6/noarch http://resources.ovirt.org/pub/ovirt-3.6/rpm/el6/noarch

    cd ${d_dest}/el6/x86_64
    wget --execute robots=off -nc -nd -r -l1 -A'*.rpm' http://resources.ovirt.org/pub/ovirt-3.6/rpm/el6/x86_64
    validate_wget ${d_dest}/el6/x86_64 http://resources.ovirt.org/pub/ovirt-3.6/rpm/el6/x86_64

############################ ovirt-deps ###############################
## [jpackage]
    tmp_jpackage="dom4j,isorelax,jaxen,jdom,msv,msv-xsdlib,relaxngDatatype,servicemix-specs,tomcat5-servlet-2.4-api,ws-jaxme,xalan-j2,xml-commons,xml-commons-jaxp-1.2-apis,xml-commons-resolver11,xom,xpp2,xpp3,antlr3,stringtemplate"
    list_jpackage=`echo ${tmp_jpackage} |sed 's/,/\-\*.rpm,/g' |awk '{print $0"-*.rpm"}'`

    cd ${d_dest}/dependencies/jpackage
    wget --execute robots=off -nc -nd -r -l1 -A ${list_jpackage} http://mirrors.dotsrc.org/jpackage/6.0/generic/free/RPMS

## [gluster]
    cd ${d_dest}/dependencies/gluster
    wget --execute robots=off -nc -nd -r -l1 -A'*.rpm' http://download.gluster.org/pub/gluster/glusterfs/LATEST/EPEL.repo/epel-6/x86_64
    wget --execute robots=off -nc -nd -r -l1 -A'*.rpm' http://download.gluster.org/pub/gluster/glusterfs/LATEST/EPEL.repo/epel-6/noarch

## [patternfly]
    cd ${d_dest}/dependencies/patternfly
    wget --execute robots=off -nc -nd -r -l2 -A'*.rpm' http://copr-be.cloud.fedoraproject.org/results/patternfly/patternfly1/epel-6-x86_64

## [others]
    cd ${d_dest}/dependencies/others
    wget --execute robots=off -nc -nd -r -l1 -A'policycoreutils-*.rpm,libnl3-*.rpm,selinux-policy-*.rpm' http://mirrors.aliyun.com/centos/6/os/x86_64/Packages
    wget --execute robots=off -nc -nd -r -l1 -A'*.rpm' http://fedorapeople.org/groups/virt/virtio-win/repo/stable

############################ createrepo ###############################
    cd /var/www/html/ovirt/ovirt-3.6/rpm/el6/
    /usr/bin/createrepo .
    cd /var/www/html/ovirt/ovirt-3.6/rpm/dependencies/
    /usr/bin/createrepo .

    exit 0
}


############################ ovirt-3.6.repo ###############################
function file_repo() {
    cat <<'_EOF' >ovirt-3.6.repo
[ovirt-3.6]
name=Latest oVirt 3.6 Release
baseurl=http://mirrors.office.test/ovirt/ovirt-3.6/rpm/el$releasever/
enabled=1
skip_if_unavailable=1
gpgcheck=0

[ovirt-3.6-others]
name=others
baseurl=http://mirrors.office.test/ovirt/ovirt-3.6/rpm/dependencies/
enabled=1
skip_if_unavailable=1
gpgcheck=0
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
