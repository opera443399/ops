#!/bin/bash
#
#2017/2/4

domain_name='http://localhost'
login_url="${domain_name}/accounts/login/"
logout_url="${domain_name}/accounts/logout/"
target_url="${domain_name}/hosts/load/vms"
username='root'
password=''
f_cookies=cookies.txt
curl_opts="-c ${f_cookies} -b ${f_cookies}"

echo "[-] Step1: get csrftoken ..."
curl -s ${curl_opts} ${login_url} >/dev/null
django_token="$(grep csrftoken ${f_cookies} | awk '{print $NF}')"

echo "[-] Step2: perform login ..."
curl ${curl_opts} ${target_url} \
    -H "X-CSRFToken: ${django_token}" \
    -d "username=${username}&password=${password}"

echo -e "\n[-] Step3: perform logout ..."
curl -L -I ${logout_url} && rm -f ${f_cookies}
