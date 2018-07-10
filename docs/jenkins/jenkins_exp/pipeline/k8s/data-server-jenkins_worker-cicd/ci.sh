#!/bin/bash
#
# 2018/7/10
###########
### 请使用 `dep` 来解决 golang 的依赖而不是使用 `go get`
### goal:
### - build golang
### - build+push docker image
### - update etcd
### login to your docker registry before push
### $ DOCKER_REGISTRY_USERNAME='xxx'
### $ DOCKER_REGISTRY_PASSWORD='xxx'
### $ echo ${DOCKER_REGISTRY_PASSWORD} |docker login --username=${DOCKER_REGISTRY_USERNAME} --password-stdin ${DOCKER_REGISTRY_URL}
###
### 适用于 k8s
###########

#set -e

# app
APP_NAME="$2"
APP_TAG="$3"
APP_SVC_NAMES="$4"
APP_CI_ROOT="/data/server/jenkins_worker/cicd/${APP_NAME}"
APP_CI_LOG_ROOT="${APP_CI_ROOT}/logs"
[ -d ${APP_CI_LOG_ROOT} ] || mkdir -p ${APP_CI_LOG_ROOT}
# docker
DOCKER_TPL_ROOT="${APP_CI_ROOT}/tpl.docker.d"
DOCKER_IMAGE_NS="ns-demo"
DOCKER_REGISTRY_URL='registry.cn-hangzhou.aliyuncs.com'
# k8s
K8S_NAMESPACE="ns-${APP_NAME}-$5"
K8S_YAML_ROOT="${APP_CI_ROOT}/k8s.yaml.d"
[ -d ${K8S_YAML_ROOT} ] || mkdir -p ${K8S_YAML_ROOT}
ETCD_ENDPOINTS='http://10.250.3.100:2379'

print_info() {
  echo "[I] -----------------> $1"
}

print_error() {
  echo "[E] _________________> $1"
}

do_build_golang_docker() {
  ##### dep howto
  # go get -v github.com/golang/dep/cmd/dep # $GOPATH/bin/dep ensure -v # $GOPATH/bin/dep status -v

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

          ### k8s config
          local f_k8s_yaml="k8s.${K8S_NAMESPACE}.yaml"
          if [ -f ${f_k8s_yaml} ]; then
            echo "[-] 当前 k8s 配置 ${f_k8s_yaml} 的 image 为：" >>${f_log_successful}
            grep image ${f_k8s_yaml} >>${f_log_successful}
            mkdir -p ${K8S_YAML_ROOT}/${K8S_NAMESPACE}
            sed -e "s#TPL_REPLACE_NS_HERE#${K8S_NAMESPACE}#" \
                -e "s#TPL_REPLACE_IMAGE_HERE#${s_tag_remote}#" \
                ${f_k8s_yaml} >"${K8S_YAML_ROOT}/${K8S_NAMESPACE}/${s_name}.yaml"
            echo "[-] 更新后的 image 为：" >>${f_log_successful}
            grep image "${K8S_YAML_ROOT}/${K8S_NAMESPACE}/${s_name}.yaml" >>${f_log_successful}
          fi

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

do_etcd_put_batch() {
  local action="$1"
  local f_key="/cicd/${action}/trigger"

  echo
  print_info "[+] 操作: ${action}  当前版本: ${APP_TAG}"
  for s_name in $(echo ${APP_SVC_NAMES} |sed 's/,/\n/g'); do
    local svc_name="$(echo ${s_name} |tr '_' '-')"
    local f_value="
    {
      \"action\":\"${action}\",
      \"k8sNamespace\":\"${K8S_NAMESPACE}\",
      \"appName\":\"${APP_NAME}\",
      \"svcName\":\"${svc_name}\",
      \"imageTag\":\"${APP_TAG}\"
    }
    "

    ### update etcd
    print_info "[-] 更新服务 ${s_name} 在 etcd 中的状态"
    ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${ETCD_ENDPOINTS}" put "${f_key}" "${f_value}"
    ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${ETCD_ENDPOINTS}" get "${f_key}"

    sleep 1
  done

  exit 0
}

print_usage() {
  cat <<_EOF

usage:
    $0 [build|rollout|undo] [APP_NAME] [APP_TAG] [APP_SVC_NAMES]

    build
                      build golang
                      build+push docker image
    rollout|undo
                      update etcd

_EOF

  exit 1
}


case $1 in
  build)
    do_build_golang_docker
    ;;
  rollout|undo)
    do_etcd_put_batch $1
    ;;
  *)
    print_usage
    ;;
esac
