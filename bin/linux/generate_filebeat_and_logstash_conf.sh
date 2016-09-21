#!/bin/bash
#
#/2016/9/21

f_yml='/tmp/filebeat.yml'
f_conf='/tmp/filebeat.conf'
#1 www
www_access=$(ls -l /var/log/nginx/access.*.com*.log |grep -F "`date +'%b %d'`" |grep -Po '(?<=access.).*.com(?=-\d+.log|.log)' |sort |uniq)
www_error=$(ls -l /var/log/nginx/error.*.com*.log |grep -F "`date +'%b %d'`" |grep -Po '(?<=error.).*.com(?=-\d+.log|.log)' |sort |uniq)


#2 filebeat
function do_yml(){
    echo -e "\n-----------------------\n[-] create : ${f_yml}"
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
        - /var/log/nginx/access.${i}*.log
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
        - /var/log/nginx/error.${i}*.log
      input_type: log
      document_type: NginxError-${i}
_EOF
    done

    #step4
    cat <<'_EOF' >>${f_yml}
  registry_file: /var/lib/filebeat/registry
output:
  logstash:
    hosts: ["10.10.10.228:5044"]
shipper:
logging:
  to_files: true
  files:
    path: /var/log/filebeat
    name: filebeat
    rotateeverybytes: 10485760 # = 10MB
_EOF
}



#3 logstash
function do_conf(){
    echo -e "\n-----------------------\n[-] create : ${f_conf}"
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
}


function do_all(){
    cat <<_EOF

[+] find domains from nginx log filenames, then generate config file for filebeat and logstash
[-] yml(filebeat):  ${f_yml}
[-] conf(logstash): ${f_conf}

_EOF
    do_yml
    do_conf
}


function usage(){

    cat <<_EOF

[+] find domains from nginx log filenames, then generate config file for filebeat and logstash

Usage:
    $0 [yml|conf|all]

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
