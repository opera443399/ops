#!/bin/bash
#
# 2018/11/21
#0 2 * * * /bin/bash -xe /usr/local/bin/jenkins-backup.sh >>/data/logs/backup/jenkins.log 2>&1 &

this_ip="$(/usr/sbin/ip a |grep global |grep brd |grep 'eth0' |awk '{print $2}' |awk -F'/' '{print $1}')"
jenkins_home='/data/server/jenkins/data'
jenkins_backup_root="/data/backup/jenkins/${this_ip}"
[ -d ${jenkins_backup_root} ] || mkdir -p ${jenkins_backup_root}
jenkins_backup_file=${jenkins_backup_root}/${this_ip}_$(date +%Y%m%d_%H%M%S).tar.gz
rotate=7


[ -z ${jenkins_backup_root} ] && exit 1
find ${jenkins_backup_root} -maxdepth 1 -type f -name '*.gz' -mtime +${rotate} -print
find ${jenkins_backup_root} -maxdepth 1 -type f -name '*.gz' -mtime +${rotate} -delete

tar zcf ${jenkins_backup_file} ${jenkins_home}

# remote backup
rsync -avzP /data/backup/jenkins/ 10.50.200.101:/data/backup/jenkins/
