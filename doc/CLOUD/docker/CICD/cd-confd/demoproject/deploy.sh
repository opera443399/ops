#!/bin/bash
#
# 2018/5/2

IS_RESET=false
REGISTRY_PREFIX="registry.cn-hangzhou.aliyuncs.com/ns-my-company"
APP_PARENT="demoproject"
APP_TAG="${2:-112233a}"
SWARM_ENV="dev"
SWARM_NET="net-${APP_PARENT}-${SWARM_ENV}"
APP_LOGS_DIR="/data/logs/${APP_PARENT}/${SWARM_ENV}"
ENV_A='xxx' \
ENV_B="xxx" \
ENV_C="xxx"


# ---
### 注意：网段不要冲突
do_net_init() {
  docker network create \
    --driver overlay \
    --subnet 172.16.200.0/24 \
    --gateway 172.16.200.1 \
    ${SWARM_NET}
  docker network inspect ${SWARM_NET}
}

# ---
do_init() {
  grep "^[^#]" svc.list >.svc

  while read app_name src_port dest_port
  do
    echo "[I] ------------> action=create, app_name=${app_name}, src_port=${src_port}, dest_port=${dest_port}"
    local app_service_name="${SWARM_ENV}-${APP_PARENT}-$(echo ${app_name} |tr '_' '-')"
    local app_image="${REGISTRY_PREFIX}/${APP_PARENT}-${app_name}:${APP_TAG}"

    docker service ls |grep "${app_service_name}"
    if test $? -eq 0; then
      echo "[E] code: $?  the service name exist!"
      if ${IS_RESET}; then
        docker service rm "${app_service_name}"
      else
        return
      fi
    fi

    docker service create \
      --name ${app_service_name} \
      --with-registry-auth \
      --detach=false \
      --restart-condition="on-failure" \
      --network=${SWARM_NET} \
      --publish ${dest_port}:${src_port} \
      --mount type=bind,src="${APP_LOGS_DIR}",dst="/var/log/demoproject" \
      --env ENV_A="${ENV_A}" \
      --env ENV_B="${ENV_B}" \
      --env ENV_C="${ENV_C}" \
      ${app_image}

  done < .svc
}

# ---
do_stop() {
  while read app_name src_port dest_port
  do
    echo "[I] ------------> action=stop, app_name=${app_name}, src_port=${src_port}, dest_port=${dest_port}"
    local app_service_name="${SWARM_ENV}-${APP_PARENT}-$(echo ${app_name} |tr '_' '-')"
    docker service rm ${app_service_name}

  done < .svc
}

# ---
do_update() {
  while read app_name src_port dest_port
  do
    echo "[I] ------------> action=update, env=${SWARM_ENV}, app=${APP_PARENT}, app_name=${app_name}"
    local app_service_name="${SWARM_ENV}-${APP_PARENT}-$(echo ${app_name} |tr '_' '-')"
    local app_image="${REGISTRY_PREFIX}/${APP_PARENT}-${app_name}:${APP_TAG}"
    docker service update --detach=false ${app_service_name} --image ${app_image}

  done < .svc
}

# ---
do_ps() {
  echo "[I]  ------------> action=ps, env=${SWARM_ENV}, app=${APP_PARENT}"
  docker service ls -f name="${SWARM_ENV}-${APP_PARENT}"
}

# ---
usage() {
cat<<_EOF

usage: $0 [init|reset|update|stop|ps|net_init]

_EOF
}

# ---
case $1 in
  init|stop|ps|update|net_init)
    do_$1
    ;;
  reset)
    IS_RESET=true
    do_init
    ;;
  *)
    usage
    ;;
esac
