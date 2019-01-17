# es run without docker

2019/1/17

## init

### jdk

```bash
wget -O jdk-11.0.2_linux-x64_bin.rpm https://download.oracle.com/otn-pub/java/jdk/11.0.2+7/f51449fcd52f4d52b93a989c5c56ed3c/jdk-11.0.2_linux-x64_bin.rpm?AuthParam=1547693507_79cd471f39aa5d6c5b938cb6501cf05f
yum localinstall jdk-10_linux-x64_bin.rpm -y

cat <<'_EOF' >>/etc/profile.conf
export JAVA_HOME=/usr/java/default
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin

_EOF

```


### elasticsearch(3 nodes for exp)

```bash
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat <<'_EOF' >/etc/yum.repos.d/elasticsearch.repo
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md

_EOF

yum install elasticsearch -y

mkdir -p /data/es/{data,log}
chown -R elasticsearch:elasticsearch /data/es

cat <<'_EOF' >/etc/elasticsearch/elasticsearch.yml
# ---------------------------------- Cluster -----------------------------------
cluster.name: docker-logs-cluster
# ------------------------------------ Node ------------------------------------
node.name: node-0
# ----------------------------------- Paths ------------------------------------
path.data: /data/es/data
path.logs: /data/es/log
# ---------------------------------- Network -----------------------------------
network.host: 10.200.3.101
http.port: 9200
# --------------------------------- Discovery ----------------------------------
discovery.zen.ping.unicast.hosts: ["10.200.3.101", "10.200.3.102", "10.200.3.103"]
discovery.zen.minimum_master_nodes: 2

_EOF

```

## run

```bash
### systemd
systemctl daemon-reload
systemctl enable elasticsearch

systemctl start elasticsearch
systemctl restart elasticsearch
systemctl stop elasticsearch


### status
systemctl status elasticsearch
journalctl -u elasticsearch --since "2019-01-17 11:56:00"

curl -X GET "10.200.3.101:9200/"
curl -X GET "10.200.3.101:9200/_cat/health?v"


```


# 参考
1. [Install Elasticsearch with RPM](https://www.elastic.co/guide/en/elasticsearch/reference/current/rpm.html)
2. [Important Elasticsearch configuration](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html)
