#!/bin/bash
#
app_name="demoproject"
cd /data/server/jenkins_worker/cicd/${app_name}
grep "^[^#]" svc.list |awk -F',' '{print $1" "$2}' >.svc

while read svc_name svc_port
do
  [ -f "tpl.docker.d/${svc_name}/Dockerfile" ] && continue
  echo "[+] CI init ${svc_name} ${svc_port}"
  mkdir -pv "tpl.docker.d/${svc_name}"
  cat <<_EOF > "tpl.docker.d/${svc_name}/Dockerfile"
FROM ns-demo/image-base-demo:v0.1

ENV D_APP_BIN '/data/server/${app_name}/'

COPY ${svc_name} \${D_APP_BIN}

RUN mkdir -p \${D_APP_BIN}/logs
WORKDIR \${D_APP_BIN}

EXPOSE ${svc_port}
ENTRYPOINT ["./${svc_name}"]

_EOF

done < .svc
