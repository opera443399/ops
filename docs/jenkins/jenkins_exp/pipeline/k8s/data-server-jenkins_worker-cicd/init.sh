#!/bin/bash
#
APP_PARENT="demoproject"
cd /data/server/jenkins_worker/cicd/${APP_PARENT}
grep "^[^#]" svc.list |awk -F',' '{print $1" "$2}' >.svc

while read svc_name svc_port
do
  [ -d "tpl.docker.d/${svc_name}" ] && continue
  echo "[+] CI init ${svc_name} ${svc_port}"
  mkdir -pv "tpl.docker.d/${svc_name}"
  cat <<_EOF > "tpl.docker.d/${svc_name}/Dockerfile"
FROM ns-demo/image-base-demo:v0.1

COPY ${svc_name} .
EXPOSE ${svc_port}
ENTRYPOINT ["./${svc_name}"]
_EOF

done < .svc
