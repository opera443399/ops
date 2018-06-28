#!/bin/bash
#
# 2018/6/28
###########
### 请使用 `dep` 来解决 golang 的依赖而不是使用 `go get`
### goal:
### - build golang
### - build+push docker image
### login to your docker registry before push
### $ DOCKER_REGISTRY_USERNAME='xxx'
### $ DOCKER_REGISTRY_PASSWORD='xxx'
### $ echo ${DOCKER_REGISTRY_PASSWORD} |docker login --username=${DOCKER_REGISTRY_USERNAME} --password-stdin ${DOCKER_REGISTRY_URL}
###
### 适用于 docker sawrm mode
###########

#set -e

APP_NAME="$2"
APP_TAG="$3"
APP_SVC_NAMES="$4"
APP_CI_ROOT="/data/server/jenkins_worker/cicd/${APP_NAME}"
APP_CI_LOG_ROOT="${APP_CI_ROOT}/logs"
DOCKER_TPL_ROOT="${APP_CI_ROOT}/tpl.docker.d"
DOCKER_IMAGE_NS="ns-demo"
DOCKER_REGISTRY_URL='registry.cn-hangzhou.aliyuncs.com'

print_info() {
  echo "[I] -----------------> $1"
}

print_error() {
  echo "[E] _________________> $1"
}


do_build_golang_docker() {
  ##### dep howto
  # go get -v github.com/golang/dep/cmd/dep
  # $GOPATH/bin/dep ensure -v
  # $GOPATH/bin/dep status -v

  local f_log_successful="${APP_CI_LOG_ROOT}/ci.successful.log"
  local f_log_failed="${APP_CI_LOG_ROOT}/ci.failed.log"
  echo >${f_log_successful}
  echo >${f_log_failed}

  for s_name in $(echo ${APP_SVC_NAMES} |sed 's/,/\n/g'); do
    echo
    print_info "使用版本： ${APP_TAG} 来构建服务： ${s_name}"

    ### go build
    if [ -d "${WORKSPACE}/${s_name}/" ]; then
      cd "${WORKSPACE}/${s_name}/"
      print_info  "清理：上次构建的 binary"
      rm -fv ./${s_name}
      print_info  "执行：GO BUILD 来构建 binary"
      go build -v
      print_info  "查看 binary 目录：$(pwd)"
      chmod +x ./${s_name}
      ls -l ./${s_name}
      ### docker build
      if [ -d "${DOCKER_TPL_ROOT}/${s_name}/" ]; then
        set -e
        cp -av ./${s_name} ${DOCKER_TPL_ROOT}/${s_name}/
        cd ${DOCKER_TPL_ROOT}/${s_name}/
        print_info "确认当前目录：$(pwd) "
        print_info "准备构建 docker image"
        if [ -e "./Dockerfile" ]; then
          ### docker build
          local s_tag_local="${DOCKER_IMAGE_NS}/${APP_NAME}-$(echo ${s_name} |tr '_' '-'):${APP_TAG}"
          local s_tag_remote="${DOCKER_REGISTRY_URL}/${s_tag_local}"
          docker build -q -t "${s_tag_local}" .

          ### docker push
          docker tag "${s_tag_local}" "${s_tag_remote}"
          docker push "${s_tag_remote}"
          echo "[+] 服务 ${s_name} 构建完成，并输出如下镜像：" >>${f_log_successful}
          echo "[-] ${s_tag_local}" >>${f_log_successful}
          echo "[-] ${s_tag_remote}" >>${f_log_successful}

          ### docker image cleanup
          ### TODO



          echo '[-] ______________________END_OF_THIS_BUILD______________________' >>${f_log_successful}
        else
          print_error "[###] 构建 ${s_name} 失败：该服务的 docker 配置目录中不存在 Dockerfile"
          print_info "[+] 构建 ${s_name} 失败：该服务的 docker 配置目录中不存在 Dockerfile" >>${f_log_failed}
        fi
      else
        ls ${DOCKER_TPL_ROOT}
        ls "${DOCKER_TPL_ROOT}/${s_name}/"
        print_error "[###] 构建 ${s_name} 失败：该服务的 docker 配置目录不存在"
        print_info "[+] 构建 ${s_name} 失败：该服务的 docker 配置目录不存在" >>${f_log_failed}
      fi
    else
      print_error "[###] 构建 ${s_name} 失败：该服务目录不存在"
      print_info "[+] 构建 ${s_name} 失败：该服务目录不存在" >>${f_log_failed}
    fi
  done

  echo
  n_succ=$(grep '+' ${f_log_successful} |wc -l)
  n_fail=$(grep '+' ${f_log_failed} |wc -l)

  print_info "成功：${n_succ}"
  if [ ${n_fail} -gt 0 ]; then
    print_info "失败：${n_fail}"
    cat ${f_log_failed}
    exit 1
  fi

  cat ${f_log_successful}
  exit 0
}



print_usage() {
  cat <<_EOF

usage:
    $0 [build] [project]

    build             构建(golang->docker)

_EOF

  exit 1
}


case $1 in
  build)
    do_build_golang_docker
    ;;
  *)
    print_usage
    ;;
esac
