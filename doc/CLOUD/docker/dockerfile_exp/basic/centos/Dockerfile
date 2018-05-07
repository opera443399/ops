FROM centos:7.2.1511
LABEL ops xxx@xxx.com
LABEL info ns-demo/image-base-centos:v0.1

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && echo 'Asia/Shanghai' >/etc/timezone \
  && mkdir -p /data/{logs,server}

WORKDIR /data/server
