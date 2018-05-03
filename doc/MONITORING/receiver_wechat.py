#!/bin/env python
# -*- coding: utf-8 -*-
# 2018/5/2


import urllib3
import json
import sys

corp_id = 'xxx'
api_secret = 'xxx'
agent_id = 'xxx'
to_party = 'xxx'
api_token_url = 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid={0}&corpsecret={1}'.format(corp_id, api_secret)
api_msg_url = 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token={0}'
http = urllib3.PoolManager()
urllib3.disable_warnings()

def get_wechat_access_token():
    resp = http.request('GET', api_token_url)
    resp_decode = json.loads(resp.data.decode('utf-8'))

    return resp_decode['access_token']


def receiver_wechat(msg):
    access_token = get_wechat_access_token()

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
    print("[{0}], resp=\n{1}".format(resp.status, resp.data))
    resp_decode = json.loads(resp.data.decode('utf-8'))

    return resp_decode


if __name__ == '__main__':
    message = sys.argv[1]
    print(message)
    receiver_wechat(message)
