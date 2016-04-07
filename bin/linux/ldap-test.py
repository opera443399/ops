#!/bin/env python
# 
# 2016/4/6

import ldap
import socket

# ldap test username and password
u = ''
p = ''

def test_port(host,port):
    sk = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sk.settimeout(1)
    try:
        sk.connect((host,port))
        print 'host:{0} port:{1} OK!'.format(host,port)
        s = 0
    except:
        print 'host:{0} port:{1} Failed!'.format(host,port)
        s = 1
    sk.close()
    return s

def ldap_login(username,password):
    try:
        host ='xxx.com'
        ports=[389,390]
        p = 0
        for port in ports:
            s = test_port(host,port)
            if s == 0:
                p = port
                break
        Server = 'ldap://{0}:{1}'.format(host,p)
        print Server
        conn = ldap.initialize(Server)
        conn.timeout = 5
        username = 'your_domain\{0}'.format(username)
        conn.set_option(ldap.OPT_REFERRALS, 0)
        conn.protocol_version = ldap.VERSION3
        conn.simple_bind_s(username, password)
        return 0
    except Exception,e:
        return None



if __name__ == '__main__':
    msg = 'error'
    if ldap_login(u,p) == 0:
        msg = 'ok'
    print(msg)
