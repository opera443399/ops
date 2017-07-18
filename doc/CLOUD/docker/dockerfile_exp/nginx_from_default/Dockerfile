FROM nginx
MAINTAINER PC

RUN echo 'test nginx' >/usr/share/html/index.html
COPY ./conf.d /etc/nginx/conf.d
EXPOSE 80