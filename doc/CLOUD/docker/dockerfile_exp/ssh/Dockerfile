FROM docker.cn/docker/centos:7
MAINTAINER pcnk

RUN yum -y update; yum clean all
RUN yum -y install openssh-server passwd; yum clean all
ADD ./start.sh /root/start.sh
RUN mkdir /var/run/sshd
RUN /bin/sed -i 's/.*session.*required.*pam_loginuid.so.*/session optional pam_loginuid.so/g' /etc/pam.d/sshd

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

RUN chmod 755 /root/start.sh
# EXPOSE 22
RUN ./root/start.sh
ENTRYPOINT ["/usr/sbin/sshd", "-D"]