#!/usr/bin/python

import sys
import socket
from struct import pack, unpack

class IPInfo(object):
    def __init__(self, dbname):    
        self.dbname = dbname
        f = open(dbname, 'rb')
        self.img = f.read()
        f.close()
        (self.firstIndex, self.lastIndex) = unpack('<II', self.img[:8])
        self.indexCount = (self.lastIndex - self.firstIndex) / 7 + 1
    
    def getString(self, offset = 0):
        o2 = self.img.find('\0', offset)
        gb2312_str = self.img[offset:o2]
        try:
            utf8_str = unicode(gb2312_str,'gb2312').encode('utf-8')
        except:
            return 'unknown'
        return utf8_str

    def getLong3(self, offset = 0):
        s = self.img[offset: offset + 3]
        s += '\0'
        return unpack('<I', s)[0]

    def getAreaAddr(self, offset = 0):
        byte = ord(self.img[offset])
        if byte == 1 or byte == 2:
            p = self.getLong3(offset + 1)
            return self.getAreaAddr(p)
        else:
            return self.getString(offset)

    def getAddr(self, offset, ip = 0):
        img = self.img
        o = offset
        byte = ord(img[o])

        if byte == 1:
            return self.getAddr(self.getLong3(o + 1))
        
        if byte == 2:
            cArea = self.getAreaAddr(self.getLong3(o + 1))
            o += 4
            aArea = self.getAreaAddr(o)
            return (cArea, aArea)
            
        if byte != 1 and byte != 2:
            cArea = self.getString(o)
            o = self.img.find('\0',o) + 1
            aArea = self.getString(o)
            return (cArea, aArea)

    def find(self, ip, l, r):
        if r - l <= 1:
            return l

        m = (l + r) / 2
        o = self.firstIndex + m * 7
        new_ip = unpack('<I', self.img[o: o+4])[0]

        if ip <= new_ip:
            return self.find(ip, l, m)
        else:
            return self.find(ip, m, r)
        
    def getIPAddr(self, ip):
        ip = unpack('!I', socket.inet_aton(ip))[0]
        i = self.find(ip, 0, self.indexCount - 1)
        o = self.firstIndex + i * 7
        o2 = self.getLong3(o + 4)
        (c, a) = self.getAddr(o2 + 4)
        return (c, a)
        
    def output(self, first, last):
        for i in range(first, last):
            o = self.firstIndex +  i * 7
            ip = socket.inet_ntoa(pack('!I', unpack('I', self.img[o:o+4])[0]))
            offset = self.getLong3(o + 4)
            (c, a) = self.getAddr(offset + 4)
            print "%s %d %s/%s" % (ip, offset, c, a)


def main():
    i = IPInfo('qqwry.dat')
    (c, a) = i.getIPAddr(sys.argv[1])
    if sys.platform == 'win32':
        c = unicode(c, 'utf-8').encode('gb2312')
        a = unicode(a, 'utf-8').encode('gb2312')
    print '%s %s/%s' % (sys.argv[1], c, a)

if __name__ == '__main__':
    main()
