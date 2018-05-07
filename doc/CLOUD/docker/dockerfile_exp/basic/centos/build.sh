s_tag="$(grep 'LABEL info ' Dockerfile |awk '{print $NF}')"
docker build -t "${s_tag}" .
