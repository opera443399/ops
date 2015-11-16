#!/usr/bin/python
import random

mac = [ 0x00, 0x16, 0x3e, random.randint(0x00, 0x7f),
random.randint(0x00, 0xff), random.randint(0x00, 0xff) ]
s = []
for item in mac:
        s.append(str("%02x" % item).upper())
print ':'.join(s)
