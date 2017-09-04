#!/bin/bash
#
#2017/9/4
#set -e

################################ global settings ################################
repo_name='dockerfile'
prefix_test='test'
registry_server='registry.xxx.com'
registry_username='xxx'
registry_password='xxx'

################################ global functions ################################
function print_debug(){
    echo -e "\n[+] __> [$(date +%F_%T)] $1\n"
}
function print_info(){
    echo -e "\n[-] --> [$(date +%F_%T)] $1\n"
}
function print_line(){
    echo -e "\n________________________________________________________________________________\n"
}
function do_confirm(){
    echo -n "need confirm[yes/no]: "
    read choice
    echo ${choice} |grep -i '^yes$' >/dev/null || exit 1
}


################################ init ################################
function do_init(){
    #you can run this script alone for testing by passing image_dir here.
    test -z ${path_to_image_dir} && path_to_image_dir=$1
    test -z ${image_version} && image_version='20170101_0000_1111'

    print_info "list files changed in 30min.\n[current work dir: $(pwd)/${path_to_image_dir}]"
    print_info "++++++++++++++++++++++"
    find ${path_to_image_dir} -cmin -30
    print_info "++++++++++++++++++++++"

    local path_to_dockerfile="${path_to_image_dir}/Dockerfile"
    if [ "X${action}" == "Xbuild" -o "X${action}" == "Xtest" ]; then
        if [ ! -f "${path_to_dockerfile}" ]; then
            print_info "Dockerfile not found for image: '${path_to_image_dir}'"
            exit 1
        fi
    fi

    if [ "X${action}" == "Xtest" ]; then
        if [ $(grep 'TEST_OFF' ${path_to_dockerfile} 1>/dev/null && echo 0 || echo 1) -eq 0 ]; then
            print_info "jump out the unittest: Detected TEST_OFF directive in Dockerfile!"
            print_line
            exit 0
        fi
        if [ $(grep '^EXPOSE' ${path_to_dockerfile} 1>/dev/null && echo 0 || echo 1) -eq 1 ]; then
            print_info "EXPOSE need defined in Dockerfile!"
            exit 1
        fi

        test_expose_ports="$(grep '^EXPOSE' ${path_to_dockerfile} |grep -Eo '[0-9]+')"
        print_info "test_expose_ports: \n${test_expose_ports}"
        if [ -z "${test_expose_ports}" ]; then
            print_info "EXPOSE port is empty in Dockerfile!"
            exit 1
        fi
    fi

    prefix_test_image_name="${prefix_test}/$(echo ${path_to_image_dir} |tr '[A-Z]' '[a-z]' |sed 's#/#_#')"
    print_info "repo: ${repo_name}, image: ${prefix_test_image_name}, version: ${image_version}"

    new_image_full_name="${prefix_test_image_name}:${image_version}"
    print_info "new_image_full_name: ${new_image_full_name}"

}


################################ build ################################
function do_build(){
    print_info '[ACTION build]'
    cd ${path_to_image_dir}
    print_debug "~]# docker build --rm -t ${new_image_full_name} ."
    docker build --rm -t ${new_image_full_name} .
    [ $? -eq 0 ] || exit 1
    print_line
}


################################ test ################################
function do_test(){
    local this_port_mapping=$1
    test -z ${this_port_mapping} && this_opts='-P' || this_opts="-p ${this_port_mapping}"

    print_info '[ACTION test]'
    new_image_id=$(docker images |grep "${prefix_test_image_name}" |grep ${image_version} |awk '{print $3}' |uniq)

    print_info 'list images:'
    print_debug "~]# docker images |grep "${prefix_test_image_name}" |grep ${image_version}"
    docker images |grep "${prefix_test_image_name}" |grep ${image_version}

    print_info 'run container:'
    print_debug "~]# docker run -d ${this_opts} ${new_image_full_name}"
    docker run -d ${this_opts} ${new_image_full_name}

    print_info '(sleep 1s)' && sleep 1s

    print_info 'Show latest running container by id:'
    print_debug "~]# docker ps -l -f ancestor='${new_image_id}'"
    docker ps -l -f ancestor="${new_image_id}"

    local cnt=$(docker ps -l -f ancestor="${new_image_id} -q" |wc -l)
	
    if [ ${cnt} -eq 1 ]; then
        print_info 'Start unittest....'
        print_info '[1/1] unittest_tcp_port'
        unittest_tcp_port "${test_expose_ports}"
    else
        print_info 'Notice: failed to run this container! Check the Dockerfile please.  ps all by id:'
        print_debug "~]# docker ps -a -f ancestor='${new_image_id}'"
        docker ps -a -f ancestor="${new_image_id}"
        exit 1
    fi
    print_line
    do_cleanup
}


function unittest_tcp_port(){
    local port_lists=$1
    local cnt_error=''
    for this_port in ${port_lists};do
        random_port=$(docker ps -l -f ancestor="${new_image_id}" |grep -Eo "[0-9]+.[0-9]+.[0-9]+.[0-9]+:[0-9]+\->${this_port}/tcp" |awk -F'->' '{print $1}' |cut -d':' -f2)
        status=$(curl -s -o /dev/null -I -f -m 3 127.0.0.1:${random_port}; echo $?)
        local is_passed=''
        local msg_code=''
        case ${status} in
            0)  is_passed='Y'; msg_code='curl: (0) OK';;
            7)  is_passed='N'; msg_code='curl: (7) Failed connect to server: Connection refused';;
            22) is_passed='Y'; msg_code='curl: (22) The requested URL returned error: http code that is >= 400';;
            28) is_passed='N'; msg_code='curl: (28) Operation timed out after 3001 milliseconds with 0 out of -1 bytes received';;
            52) is_passed='Y'; msg_code='curl: (52) Empty reply from server';;
            56) is_passed='N'; msg_code='curl: (56) Recv failure: Connection reset by peer';;
            *)  is_passed='N'; msg_code="curl: (${status}) Undefined";;
        esac
        cnt_error=${cnt_error}"${is_passed}"
        echo -e "${this_port} -> ${is_passed}                [curl msg: ${msg_code}]"
    done

    echo ${cnt_error} |grep 'N' >/dev/null && is_failed=1 || is_failed=0
    echo -n "unittest status: ${cnt_error}, result: "

    if [ ${is_failed} -eq 1 ]; then
        echo "Failure"
        exit 1
    else
        echo "Success"
    fi
}


################################ push ################################
function do_push(){
    print_info '[ACTION push]'
    print_debug "~]# docker login -u xxx -p xxx ${registry_server}"
    docker login -u ${registry_username} -p ${registry_password} ${registry_server}

    print_debug "~]# docker tag ${new_image_full_name} ${registry_server}/${new_image_full_name}"
    docker tag ${new_image_full_name} ${registry_server}/${new_image_full_name}

    print_debug "~]# docker push ${registry_server}/${new_image_full_name}"
    docker push ${registry_server}/${new_image_full_name}
}


################################ cleanup ################################
function do_cleanup(){
    print_debug 'do cleanup:'
    local cnt=$(docker ps -f ancestor="${new_image_id} -q" |wc -l)
    if [ ${cnt} -gt 0 ]; then
        print_info 'delete all the containers as given below:'
        print_debug "~]# docker ps -f ancestor='${new_image_id}'"
        docker ps -f ancestor="${new_image_id}"
        print_info 'do delete:'
        print_debug "~]# docker rm -f $(docker ps -f ancestor='${new_image_id}' -q)"
        docker rm -f $(docker ps -f ancestor="${new_image_id}" -q)
    else
        print_info "no container found for image_id='${new_image_id}'"
    fi
    print_line
}


function do_cleanup_containers_by_keyword(){
    local keyword=$1
    test -z ${keyword} && exit 1
    print_info "remove all the containers for keyword: ${keyword}"
    print_debug "~]# docker rm -f $(docker ps -a |grep "${keyword}" |grep -v 'CONTAINER ID' |awk '{print $1}')"
    do_confirm
    docker rm -f $(docker ps -a |grep "${keyword}" |grep -v 'CONTAINER ID' |awk '{print $1}')
}


function do_cleanup_images_by_keyword(){
    local keyword=$1
    test -z ${keyword} && exit 1
    print_info "remove all the images for keyword: ${keyword}"
    print_debug "~]# docker rmi -f $(docker images |grep "^${keyword}" |awk '{print $3}')"
    do_confirm
    docker rmi -f $(docker images -a |grep "^${keyword}" |awk '{print $3}')
} 


function do_cleanup_containers_not_running(){
    print_info 'This will display containers not in running status.'
    local cnt=$(docker ps --filter "status=created" --filter "status=exited" -q |wc -l)
    if [ ${cnt} -gt 0 ]; then
        print_debug '~]# docker ps --filter "status=created" --filter "status=exited"'
        docker ps --filter "status=created" --filter "status=exited"
        docker rm -f $(docker ps --filter status=created --filter status=exited -q)
    else
        print_info 'not found.'
    fi
}


function do_cleanup_images_untagged(){
    print_info 'This will display untagged images that are the leaves of the images tree (not intermediary layers). These images occur when a new build of an image takes the repo:tag away from the image ID, leaving it as <none>:<none> or untagged. A warning will be issued if trying to remove an image when a container is presently using it.'
    local cnt=$(docker images --filter "dangling=true" -q |wc -l)
    if [ ${cnt} -gt 0 ]; then
        print_debug '~]# docker images --filter "dangling=true"'
        docker images --filter "dangling=true"
        print_debug '~]# docker rmi $(docker images -f "dangling=true" -q)'
        docker rmi $(docker images -f "dangling=true" -q)
    else
        print_info 'not found.'
    fi
}


################################ main ################################
function usage(){
    cat <<_EOF

usage: 

ci:
    $0 [build|test|push|cleanup] [path_to_image_dir]

cleanup containers/images:
    $0 [rmc] keyword
    $0 [rmi] keyword

cleanup containers(created,exited), images(untagged), unused volumes and networks:
    $0 [prune]

_EOF
}

case $1 in
    build|test|push|cleanup)
        action=$1
        shift
        do_init $1
        shift
        do_${action} $@
        ;;
    rmc)
        shift
        do_cleanup_containers_by_keyword $1
        ;;
    rmi)
        shift
        do_cleanup_images_by_keyword $1
        ;;
    prune)
        docker system prune
        docker image prune
        do_cleanup_containers_not_running
        #do_cleanup_images_untagged
        ;;
    *)
        usage
        exit 1
        ;;
esac
