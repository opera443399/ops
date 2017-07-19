FROM centos:6.8
MAINTAINER PC

ENV NGINX_VERSION 1.12.1
RUN yum install -y gcc gcc-c++ openssl-devel pcre-devel; yum clean all
COPY ./nginx-${NGINX_VERSION}.tar.gz .
RUN tar zxf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && ./configure \
    --prefix=/usr/local/nginx \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-pcre \
    --with-http_realip_module \
    && make \
    && make install \
    && rm -f nginx-${NGINX_VERSION}.tar.gz

RUN useradd -s /sbin/nologin -d /var/lib/nginx -c "Nginx Web Server" nginx

COPY ./nginx.conf /usr/local/nginx/conf/nginx.conf
COPY ./conf.d /usr/local/nginx/conf/conf.d

ENV NGINX_WWWROOT /data/websites
ENV NGINX_LOGROOT /data/logs/nginx
ENV NGINX_DEFAULT_SITE www.test.com
RUN mkdir -p ${NGINX_WWWROOT}/${NGINX_DEFAULT_SITE} ${NGINX_LOGROOT}

EXPOSE 80
ENTRYPOINT ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]