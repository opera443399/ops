#!/bin/env python3
# filename: zabbix_get_graph.py
# 2013-03-05 17:25 by PC

import http.cookiejar, urllib.request, urllib.error, urllib.parse
import os

def set_cookie(url, kv):
    header = {'User-Agent':'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.19 (KHTML, like Gecko) Chrome/25.0.1323.1 Safari/537.19'}

    cj = http.cookiejar.CookieJar()
    cp = urllib.request.HTTPCookieProcessor(cj)
    opener = urllib.request.build_opener(cp)
    urllib.request.install_opener(opener)

    url_kv = urllib.parse.urlencode(kv)

    req = urllib.request.Request(url)
    for k in header:
        req.add_header(k, header[k])

    try:    
        resp = urllib.request.urlopen(req, url_kv.encode('utf-8'))
    except urllib.error.HTTPError as e:
        print('Error code:', e.code)
        if e.code == 302:
            print("It's OK, trust me!")
    except urllib.error.URLError as e:
        print('Reason:', e.reason)
    else:
        content = resp.read()
        print(content)

def get_graph(host, graphid, period, stime):
    url = '''\
http://{host}/chart2.php?graphid={graphid}&period={period}&stime={stime}&width=1296
'''.format(host=host,
           graphid=graphid,
           period=period,
           stime=stime)
    print('-'*10,'\n', url)
    img_req = urllib.request.Request(url)
    png = urllib.request.urlopen(img_req).read()

    
    fn = '{0}graph{1}.png'.format(os.path.abspath('.'), graphid)
    print('Graph output to file: "{0}"'.format(fn))
    with open(fn,'wb') as f:
        f.write(png)

if __name__ == '__main__':
    kv = {
        'name': 'admin',
        'password': 'admin',
        'autologin': 1,
        'enter':'Sign in'
        }
    host = '192.168.1.240'
    set_cookie('http://{0}/index.php'.format(host), kv)
    get_graph(host, 527, 3600, 20130512094530)
