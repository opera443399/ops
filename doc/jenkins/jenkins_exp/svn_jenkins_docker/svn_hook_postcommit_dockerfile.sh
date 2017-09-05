#!/bin/bash
#
#2017/9/4

svn_repository="$1"
svn_repository_revision="$2"
f_log='/tmp/svn_hook_postcommit_dockerfile.log'

function do_curl(){
    jenkins_server='192.168.1.100:8080'
    jenkins_api_token='admin:462c0f17eb4092e2f7bb5807c23e6ffc'
    #curl -s 'http://admin:password@${jenkins_server}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'
    jenkins_crumb='Jenkins-Crumb:35fs92e2f723e6ff353c0f17cbb5807c'
    jenkins_token='build_test'
    #curl -I -X POST http://${jenkins_api_token}@${jenkins_server}/job/job01/build -H "${jenkins_crumb}"
    curl -s \
-H "${jenkins_crumb}" \
--data-urlencode json="
{
    \"parameter\": [
        {
            \"name\": \"path_to_image_dir\", 
            \"value\": \"${docker_image_dir}\"
        },
        {
            \"name\": \"image_version\", 
            \"value\": \"${docker_image_version}\"
        },
        {
            \"name\": \"image_name_with_version\", 
            \"value\": \"${docker_image_name_with_version}\"
        }
    ]
}
" "http://${jenkins_api_token}@${jenkins_server}/job/job01/build?token=${jenkins_token}"

}

function do_filter_changed(){
    echo "[debug] svn_repository: ${svn_repository}, svn_repository_revision: ${svn_repository_revision}"
    for d in $(/usr/bin/svnlook changed -r ${svn_repository_revision} ${svn_repository} |awk '{print $2}' |grep '^.*\/.*\/' |awk -F'/' '{print $1"/"$2}' |sort |uniq)
    do  
        echo "[debug] dir: $d"
        docker_image_dir="$d"
        docker_image_version="$(date +%Y%m)_${svn_repository_revision}"
        docker_image_name_with_version="$(echo ${docker_image_dir} |tr '[A-Z]' '[a-z]' |sed 's#/#_#'):${docker_image_version}"
        echo -e "[debug] \nimage path -> ${docker_image_dir} \nversion -> ${docker_image_version} \nimage:tag -> ${docker_image_name_with_version} \n"
        do_curl
    done
    echo "[debug] the end. (if no more lines above, which means current commit faild, you must check the structure: 'svn/projectname/imagename/files')"
}

echo "--------------------[`date`]----------------------" >>${f_log}
do_filter_changed >>${f_log}
