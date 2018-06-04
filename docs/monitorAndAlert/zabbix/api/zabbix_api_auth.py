#!/bin/env python3
# filename: zabbix_api_auth.py
# 2013-03-06 10:30 by PC

import json
import urllib.request, urllib.error

url = "http://192.168.1.240/api_jsonrpc.php"
header = {
        "Content-Type": "application/json"
        }

def get_auth_key(url, header):
    auth_data = json.dumps(
        {
            "jsonrpc": "2.0",
            "method": "user.login",
            "params":
            {
                "user": "admin",
                "password": "Test2013"
            },
            "auth": None,
            "id": 0
        })

    auth_req = urllib.request.Request(url, auth_data.encode('utf-8'))

    for k in header:
        auth_req.add_header(k, header[k])

    try:
        auth_result = urllib.request.urlopen(auth_req)
        auth_resp = json.loads(auth_result.read().decode('utf-8'))
        auth_key = auth_resp['result']
    except urllib.error.HTTPError as e:
        print('Error code:', e.code)
    except urllib.error.URLError as e:
        print('Reason:', e.reason)
    except KeyError as e:
        print('KeyError:', e)
        print('json content:\n',auth_resp)
    else:
        print("auth id is: ", auth_key)
        return auth_key
    finally:
        auth_result.close()

    return -1

def get_hosts_by_akey(url, header, akey):
    host_data = json.dumps(
        {
            "jsonrpc": "2.0",
            "method": "host.get",
            "params":
            {
                "output": ["hostid","name"],
                "filter": {"host":""}
            },
            "auth": akey,
            "id": 1
        })

    host_req = urllib.request.Request(url, host_data.encode('utf-8'))

    for k in header:
        host_req.add_header(k, header[k])

    try:
        host_result = urllib.request.urlopen(host_req)
    except urllib.error.URLError as e:
        print(e)
    else:
        host_resp = json.loads(host_result.read().decode('utf-8'))
        hosts = host_resp['result']
        for h in hosts:
            print("HOSTID :{0}, NAME :{1};".format(h['hostid'], h['name'])) 
    finally:
        host_result.close()
    


akey = get_auth_key(url, header)
get_hosts_by_akey(url, header, akey)


curl_usage =\
'''
curl howto--
#user.login:

curl -i -X POST \
-H 'Content-Type:application/json' \
-d '{"jsonrpc": "2.0","method":"user.login","params":{"user":"admin","password":"admin"},"auth": null,"id":0}' \
http://192.168.1.240/api_jsonrpc.php

#host.get:
curl -i -X POST \
-H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"host.get","params":{"output":["hostid","name"],"filter":{"host":""}},"auth":"2d3d45bc8ecadae82055162b40ae5216","id":1}' \
http://192.168.1.240/api_jsonrpc.php
'''

print(curl_usage)
