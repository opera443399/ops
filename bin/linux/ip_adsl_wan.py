#!/bin/env python3


import urllib.request
import re

def get_public_ip():
    fs = urllib.request.urlopen(r'http://1111.ip138.com/ic.asp')
    fb = fs.read()
    string = fb.decode('gb2312')
    fs.close()
    #print(string)
    #pattern = r'''\d+\.\d+\.\d+\.\d+'''
    pattern = r'''<center>(.*)</center>'''    
    ips = re.findall(pattern, string, re.VERBOSE)
    
    return ips[0]


print(get_public_ip())
