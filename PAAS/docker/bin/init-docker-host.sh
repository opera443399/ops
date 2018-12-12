#!/bin/bash
#
# 2018/11/21

yum -y install yum-utils \
&& yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo \
&& yum makecache fast \
&& yum -y install docker-ce-18.03.1.ce-1.el7.centos.x86_64 \
&& mkdir -p /data/server/docker \
&& mkdir -p /etc/docker; tee /etc/docker/daemon.json <<-'EOF'
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true,
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "graph": "/data/server/docker",
  "storage-driver": "overlay",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "1024m"
  },
  "registry-mirrors": ["https://xxx.mirror.aliyuncs.com"]
}


EOF
systemctl daemon-reload && systemctl enable docker && systemctl start docker

cat <<'_EOF' > /usr/local/bin/docker-cleanup.sh
#!/bin/bash
#
# 0 3 * * * sh -xe /usr/local/bin/docker-cleanup.sh >/dev/null 2>&1 &

docker image prune --filter "until=24h" --force

_EOF
chmod +x /usr/local/bin/docker-cleanup.sh

cat <<'_EOF' >> /var/spool/cron/root
## pengchao@ofo.com
0 13,23 * * * sh -xe /usr/local/bin/docker-cleanup.sh >/dev/null 2>&1 &

_EOF

echo '[+] docker version:'
docker version
echo '[+] crontab added:'
crontab -l
