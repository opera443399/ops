#!/bin/env python
# 
# 2015/08/10

import random

class RandChars(object):
    '''
    RandChars(24).generate()
    '''
    # char pools
    pools = '23456789'
    pools += 'abcdefghijkmnpqrstuvwxyz'
    pools += 'ABCDEFGHIJKMNPQRSTUVWXYZ'
    pools += '~!@#$%^&*()_+'
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
    try:
        while True:
            print('[-] [press `Ctrl+C` to cancel], default=24: ')
            length = raw_input('Length to generate: ')
            # python3
            #length = input('Length: ')

            if not length:
                length = '24'
            if length.isdigit():
                print('\n\n{0}\n\n'.format(RandChars(int(length)).generate()))
            else:
                print('\n[WARNING] hi, length is digit.\n')
    except KeyboardInterrupt:
        print('\n\n[NOTICE] You cancelled the operation.\n')
    except Exception as err:
        print('\n[ERROR]: {0}\n'.format(err))
