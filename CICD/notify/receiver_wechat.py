#!/bin/env python
# -*- coding: utf-8 -*-
# 2018/11/2


import urllib3
import certifi
import json
import os
import sys
from datetime import datetime

# less than 7200 sec
dt_token_expire_seconds = 7000
token_file_prefix = "{0}/.wxtoken".format(os.path.expanduser('~'))
# wechat config
corp_id = 'xxx'
multi_conf = {
    "g1": {"api_secret": "xxx", "agent_id": "1000002", "to_party": "2"},
    "g2": {"api_secret": "xxx", "agent_id": "1000004", "to_party": "4"},
    }

http = urllib3.PoolManager(cert_reqs='CERT_REQUIRED', ca_certs=certifi.where())
urllib3.disable_warnings()


def renew_wechat_access_token(session):
    resp = http.request('GET', api_token_url)
    resp_decode = json.loads(resp.data.decode('utf-8'))
    with open(session, "w+") as f:
        f.write("{0},{1}".format(datetime.now().strftime("%Y-%m-%d %H:%M:%S"), resp_decode['access_token']))
    return resp_decode['access_token']


def get_wechat_access_token(session):
    try:
        with open(session) as f:
            x, y = f.readline().split(",")
    except:
        return renew_wechat_access_token(session)

    print("cache time: {0}".format(x))
    dt1 = datetime.now()
    dt2 = datetime.strptime(x, "%Y-%m-%d %H:%M:%S")
    dt_days_delta = (dt1 - dt2).days
    dt_seconds_delta = (dt1 - dt2).seconds

    if dt_days_delta == 0 and dt_seconds_delta < dt_token_expire_seconds:
        print("token is in use for {0} seconds.".format(dt_seconds_delta))
        return y
    else:
        print("renew token...")
        return renew_wechat_access_token(session)


def receiver_wechat(msg):
    access_token = get_wechat_access_token("{0}.{1}".format(token_file_prefix, agent_id))

    api_sent_url = api_msg_url.format(access_token)
    data = {
        "agentid": agent_id,
        "toparty": to_party,
        "msgtype": "text",
        "text": {
            "content": msg
        }
    }
    encoded_data = json.dumps(data).encode('utf-8')

    resp = http.request('POST', api_sent_url, body=encoded_data, headers={'Content-Type': 'application/json'})
    print("[-] 'status': '{0}', 'resp': '{1}'".format(resp.status, resp.data))
    resp_decode = json.loads(resp.data.decode('utf-8'))

    return resp_decode


if __name__ == '__main__':
    alert_group = sys.argv[1]
    message = sys.argv[2]
    print("[+] 'alert_group': '{0}'".format(alert_group))
    print("[+] 'message': ")
    print('#'*79)
    print("{0}".format(message))
    print('#'*79)
    api_secret = multi_conf[alert_group]["api_secret"]
    agent_id = multi_conf[alert_group]["agent_id"]
    to_party = multi_conf[alert_group]["to_party"]
    api_token_url = 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid={0}&corpsecret={1}'.format(corp_id, api_secret)
    api_msg_url = 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token={0}'

    #get_wechat_access_token()
    receiver_wechat(message)
