#!/bin/env python
# -*- coding:utf-8 -*-
#
# 2018/11/21

from __future__ import print_function
import random

class RandChars(object):
    '''
    RandChars(24).generate()
    '''
    # char pools
    pools = '23456789'
    pools += 'abcdefghijkmnpqrstuvwxyz'
    pools += 'ABCDEFGHIJKMNPQRSTUVWXYZ'
    #pools += '~!@#$%^&*()_+'
    
    # pool size
    pool_size = len(pools)

    def __init__(self, length=12):
        self.length = length

    # get a char from pool
    def fetch_one(self):
        rnd_index = random.randint(0, self.pool_size-1)
        return self.pools[rnd_index]

    # map the password by index
    def generate(self):
        rnd_chars = ''
        i = 0
        while i < self.length:
            rnd_chars += self.fetch_one()
            i += 1
        return rnd_chars

if __name__ == '__main__':
    print('{0}'.format(RandChars(12).generate()))
