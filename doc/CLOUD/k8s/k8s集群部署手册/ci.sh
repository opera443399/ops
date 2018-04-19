#!/bin/bash
#
# 2018/4/19
###########
### 请使用 `dep` 来解决 golang 的依赖而不是使用 `go get`
### goal:
### - build
### - rollout
### - undo
### login to your docker registry before push
### $ DOCKER_REGISTRY_USERNAME='xxx'
### $ DOCKER_REGISTRY_PASSWORD='xxx'
### $ echo ${DOCKER_REGISTRY_PASSWORD} |docker login --username=${DOCKER_REGISTRY_USERNAME} --password-stdin ${DOCKER_REGISTRY_URL}
###########

#set -e

APP_PARENT='demoproject'
APP_CI_ROOT="/data/server/jenkins_node_workspace/cicd/${APP_PARENT}"
DOCKER_TPL_ROOT="${APP_CI_ROOT}/tpl.docker.d"
K8S_YAML_ROOT="${APP_CI_ROOT}/k8s.yaml.d"
DOCKER_IMAGE_NS="ns-my-company"
DOCKER_REGISTRY_URL='registry.cn-hangzhou.aliyuncs.com'
ETCD_ENDPOINTS='http://10.250.3.100:2379'

print_info() {
  echo "[I] -----------------> $1"
}

print_debug() {
  if ${LOG_LEVEL_DEBUG}; then
    echo "[D] -----------------> $1"
  fi
}

print_error() {
  echo "[E] _________________> $1"
}


if [ "X${SVC_VERSION}"=="XEMPTY" ]; then
  print_debug '[+] 由于版本号参数 "VERSION" 为 "EMPTY" ，提取 "git rev" 来作为 [docker image tag] 的值'
  s_version="$(git rev-parse --short HEAD)"
fi


do_etcd_put_rollout() {
  local f_appName="$(echo $1 |tr '_' '-')"
  local f_key="/k8s-deploy/${APP_PARENT}/rollout"
  local f_value="{\"k8sNamespace\":\"${K8S_NAMESPACE}\",\"appParent\":\"${APP_PARENT}\",\"appName\":\"${f_appName}\",\"imageLatest\":\"$2\"}"

  ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${ETCD_ENDPOINTS}" put ${f_key} ${f_value}
  ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${ETCD_ENDPOINTS}" put ${f_key} ${f_value}
  ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${ETCD_ENDPOINTS}" get ${f_key}
}

do_etcd_put_undo() {
  local f_appName="$(echo $1 |tr '_' '-')"
  local f_key="/k8s-deploy/${APP_PARENT}/undo"
  local f_value="{\"k8sNamespace\":\"${K8S_NAMESPACE}\",\"appParent\":\"${APP_PARENT}\",\"appName\":\"${f_appName}\",\"undoTimestamp\":\"$(date +%F"T"%T)\"}"

  ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${ETCD_ENDPOINTS}" put ${f_key} ${f_value}
  ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${ETCD_ENDPOINTS}" put ${f_key} ${f_value}
  ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints "${ETCD_ENDPOINTS}" get ${f_key}
}


do_build_golang_docker() {
  ##### dep howto
  # go get -v github.com/golang/dep/cmd/dep
  # $GOPATH/bin/dep ensure -v
  # $GOPATH/bin/dep status -v

  local f_log_successful="/tmp/ci.successful.log"
  local f_log_failed="/tmp/ci.failed.log"
  echo >${f_log_successful}
  echo >${f_log_failed}

  for s_name in $(echo ${SVC_NAMES} |sed 's/,/\n/g'); do
    echo
    print_info "使用版本： ${s_version} 来构建服务： ${s_name}"

    ### go build
    if [ -d "${WORKSPACE}/${s_name}/" ]; then
      cd "${WORKSPACE}/${s_name}/"
      print_debug  "清理：上次构建的 binary"
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
        print_debug "确认当前目录：$(pwd) "
        print_info "准备构建 docker image"
        if [ -e "./Dockerfile" ]; then
          ### docker build
          local s_tag_local="${DOCKER_IMAGE_NS}/${APP_PARENT}-${s_name}:${s_version}"
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
  cat ${f_log_successful}

  if [ ${n_fail} -gt 0 ]; then
    print_info "失败：${n_fail}"
    cat ${f_log_failed}
    exit 1
  fi

  exit 0
}


do_rollout_to_etcd() {
  for s_name in $(echo ${SVC_NAMES} |sed 's/,/\n/g'); do
    echo
    print_info "[+] 准备上线： ${s_name} 版本： ${s_version}"

    ### update etcd
    local s_tag_local="${DOCKER_IMAGE_NS}/${APP_PARENT}-${s_name}:${s_version}"
    local s_tag_remote="${DOCKER_REGISTRY_URL}/${s_tag_local}"
    ### update etcd
    print_info "[-] 更新服务 ${s_name} 在 etcd 中的 rollout 信息"
    do_etcd_put_rollout ${s_name} ${s_tag_remote}

    sleep 1
  done

  exit 0
}


do_undo_to_etcd() {
  for s_name in $(echo ${SVC_NAMES} |sed 's/,/\n/g'); do
    echo
    print_info "[+] 准备回滚： ${s_name} 版本： ${s_version}"

    ### update etcd
    print_info "[-] 更新服务 ${s_name} 在 etcd 中的 undo 信息"
    do_etcd_put_undo ${s_name}

  done

  exit 0
}


print_usage() {
  cat <<_EOF

usage:
    $0 [build|rollout|undo]

    build             构建(golang->docker)
    rollout           上线(etcd->k8s)
    undo              回滚(etcd->k8s)

_EOF
}


case $1 in
  build)
    do_build_golang_docker
    ;;
  rollout)
    do_rollout_to_etcd
    ;;
  undo)
    do_undo_to_etcd
    ;;
  *)
    print_usage
    ;;
esac
