#!/bin/bash
#
# 2018/12/14

REGISTRY_PREFIX="registry.cn-hangzhou.aliyuncs.com/ns-demo"
APP_NAME="app1"
RUN_ENV="$2"
APP_TAG="$3"
SVC_NAMES="$4"
SWARM_NET="net-${APP_NAME}-${RUN_ENV}"
APP_LOGS_DIR="/data/logs/${APP_NAME}/${RUN_ENV}"
DEPLOY_ENV="ns-${APP_NAME}-${RUN_ENV}"

print_info() {
  echo "[-] $1"
}

print_error() {
  echo "[E] ___> $1"
}

# ---
do_init() {
  grep "^[^#]" init-svc-${RUN_ENV} >.svc.${RUN_ENV}

  while read svc_name src_port dest_port
  do
    local app_service_name="${RUN_ENV}-${APP_NAME}-$(echo ${svc_name} |tr '_' '-')"
    local app_image="${REGISTRY_PREFIX}/${APP_NAME}-${svc_name}:${APP_TAG}"

    docker service ls |grep "${app_service_name}"
    if test $? -eq 0; then
      print_error "[code=$?] 服务名已经存在！"
    else
      print_info "[create] ${app_service_name}"
      docker service create \
        --name ${app_service_name} \
        --with-registry-auth \
        --detach=false \
        --restart-condition="on-failure" \
        --network=${SWARM_NET} \
        --publish ${dest_port}:${src_port} \
        --mount type=bind,src="${APP_LOGS_DIR}",dst="/var/log/app" \
        --container-label "aliyun.logs.${APP_NAME}-stdout=stdout" \
        --container-label "aliyun.logs.${APP_NAME}-file=/var/log/app/*.log" \
        --env DEPLOY_ENV="${DEPLOY_ENV}" \
        ${app_image}
    fi

  done < .svc.${RUN_ENV}
}

# ---
do_stop() {
  while read svc_name src_port dest_port
  do
    local app_service_name="${RUN_ENV}-${APP_NAME}-$(echo ${svc_name} |tr '_' '-')"
    print_info "[stop] ${app_service_name}"
    docker service rm ${app_service_name}

  done < .svc.${RUN_ENV}
}

# ---
do_update() {
  if [ -z ${SVC_NAMES} ]; then
    print_error "微服务列表为空！"
    exit 1
  else
    print_info "微服务列表如下： "
    print_info "${SVC_NAMES}"
  fi

  for svc_name in $(echo ${SVC_NAMES} |sed 's/,/\n/g')
  do
    local app_service_name="${RUN_ENV}-${APP_NAME}-$(echo ${svc_name} |tr '_' '-')"
    local app_image="${REGISTRY_PREFIX}/${APP_NAME}-${svc_name}:${APP_TAG}"
    local old_app_tag=$(docker service ls -f name="${RUN_ENV}-${APP_NAME}-${svc_name}" --format='{{ .Image }}' |cut -d':' -f2)

    print_info "[update] ${app_service_name}"
    if [ "X${old_app_tag}" == "X${APP_TAG}" ]; then
      print_info "对比镜像版本：一致"
    else
      print_info "对比镜像版本：不一致"
      print_info "更新镜像: ${old_app_tag} -> ${APP_TAG}"
      docker service update --with-registry-auth --detach=false ${app_service_name} --image ${app_image}
    fi
  done
}

# ---
do_rollback() {
  if [ -z ${SVC_NAMES} ]; then
    print_error "微服务列表为空！"
    exit 1
  else
    print_info "微服务列表如下： "
    print_info "${SVC_NAMES}"
  fi

  for svc_name in $(echo ${SVC_NAMES} |sed 's/,/\n/g')
  do
    local app_service_name="${RUN_ENV}-${APP_NAME}-$(echo ${svc_name} |tr '_' '-')"
    print_info "[rollback] ${app_service_name}"
    docker service rollback --detach=false ${app_service_name}
  done
}

# ---
do_ps() {
  echo "[I]  ___> [ps], ${RUN_ENV}-${APP_NAME}"
  docker service ls -f name="${RUN_ENV}-${APP_NAME}"
}

# ---
do_snapshot() {
  docker service ls |grep "${APP_NAME}-" |sort -k6 |awk '{print $2" "$5}' >.online

  echo "[snapshot] $(date +%FT%T)" >>snapshot.online
  while read app_service_name app_image
  do
  cat <<_EOF >>snapshot.online
docker service update --with-registry-auth --detach=false ${app_service_name} --image ${app_image}
_EOF
  done <.online
  echo "---" >>snapshot.online
}

# ---
usage() {
cat<<_EOF

usage:

    $0 init env app_tag
    $0 ps env
    $0 stop env
    $0 update env app_tag svc_name_list
    $0 rollback env app_tag svc_name_list
    $0 snapshot

_EOF
}

# ---
case $1 in
  init|ps|rollback|snapshot|stop|update)
    do_$1
    ;;
  *)
    usage
    ;;
esac
[
