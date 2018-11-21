#!/bin/bash
#
#/2016/9/23

f_yml='/tmp/filebeat.yml'
f_conf='/tmp/filebeat.conf'
####1 define the log file path
## 默认的日志路径为：/var/log/nginx/
www_access_path_prefix='/var/log/nginx/access_'
www_error_path_prefix='/var/log/nginx/error_'
## 请配置要收集的日志文件对应的域名，可以直接一行一行的列出，也可以使用命令收集。
## 请取消 www_access 到 www_error 之间的注释

####A）示范直接列出所有的文件路径
#www_access='
#www.test.com
#www.work.com
#'
#www_error=$www_access

####B）示范匹配今天生成的日志文件，提取出域名
www_access=$(ls -l /var/log/nginx/access_*.com*.log |grep -F "`date +'%b %d'`" |grep -Po '(?<=access_).*.com(?=[_-]\d+.log|.log)' |sort |uniq)
www_error=$(ls -l /var/log/nginx/error_*.com*.log |grep -F "`date +'%b %d'`" |grep -Po '(?<=error_).*.com(?=[_-]\d+.log|.log)' |sort |uniq)


####2 filebeat
## 请调整配置以符合自己的需求
function do_yml(){
    echo -e "\n-----------------------\n\033[32m[-] Create : ${f_yml}\033[0m"
    #step1
    cat <<'_EOF' >${f_yml}
filebeat:
  prospectors:
_EOF

    #step2
    for i in ${www_access}; do
        echo "[access] ${i}"
        cat <<_EOF >>${f_yml}
    -
      paths:
        - ${www_access_path_prefix}${i}*.log
      input_type: log
      document_type: NginxAccess-${i}
_EOF
    done

    #step3
    for i in ${www_error}; do
        echo "[error] ${i}"
        cat <<_EOF >>${f_yml}
    -
      paths:
        - ${www_error_path_prefix}${i}*.log
      input_type: log
      document_type: NginxError-${i}
_EOF
    done

    #step4
    cat <<'_EOF' >>${f_yml}
  registry_file: /var/lib/filebeat/registry
output:
  logstash:
    hosts: ["10.50.200.220:5044"]
shipper:
logging:
  to_files: true
  files:
    path: /var/log/filebeat
    name: filebeat
    rotateeverybytes: 10485760 # = 10MB
_EOF
    echo -e "\n\033[32m[-] Done.\033[0m\n"
}



####3 logstash
## 请调整配置以符合自己的需求
function do_conf(){
    echo -e "\n-----------------------\n\033[32m[-] Create : ${f_conf}\033[0m"
    #step1
    cat <<'_EOF' >${f_conf}
input {
    beats {
        port => "5044"
    }
}

filter {
    if[type] =~ "NginxAccess-" {
        grok {
            patterns_dir => ["/etc/logstash/patterns.d"]
            match => {
                "message" => "%{NGINXACCESS}"
            }
        }
        date {
            match => [ "timestamp", "dd/MMM/YYYY:HH:mm:ss Z" ]
            remove_field => [ "timestamp" ]
        }
    }
    if[type] =~ "NginxError-" {
        grok {
            patterns_dir => ["/etc/logstash/patterns.d"]
            match => {
                "message" => "%{NGINXERROR}"
            }
        }
        date {
            match => [ "timestamp", "YYYY/MM/dd HH:mm:ss" ]
            remove_field => [ "timestamp" ]
        }
    }
}

output {
_EOF

    #step2
    for i in ${www_access}; do
        echo "[access] ${i}"
        cat <<_EOF >>${f_conf}
    if[type] == "NginxAccess-${i}" {
        elasticsearch {
            hosts => "127.0.0.1:9200"
            manage_template => false
            index => "%{[@metadata][beat]}-nginxaccess-${i}-%{+YYYY.MM.dd}"
            document_type => "%{[@metadata][type]}"
        }
    }
_EOF
    done

    #step3
    for i in ${www_error}; do
        echo "[error] ${i}"
        cat <<_EOF >>${f_conf}
    if[type] == "NginxError-${i}" {
        elasticsearch {
            hosts => "127.0.0.1:9200"
            manage_template => false
            index => "%{[@metadata][beat]}-nginxerror-${i}-%{+YYYY.MM.dd}"
            document_type => "%{[@metadata][type]}"
        }
    }
_EOF
    done

    #step4
    cat <<'_EOF' >>${f_conf}
}
_EOF
    echo -e "\n\033[32m[-] Done.\033[0m\n"
}


function do_all(){
    do_yml
    do_conf
}


function usage(){

    cat <<_EOF

[+] 根据指定的域名来生成对应的 filebeat 和 logstash 的配置文件。

Usage:
    $0 [yml|conf|all]
    $0 yml    filebeat 的配置文件
    $0 conf   logstash 的配置文件
    $0 all

_EOF
}

case $1 in
    yml|conf|all)
        do_$1
        ;;
    *)
        usage
        exit 1
esac
