#!/usr/bin/python

import os.path
import fileinput

######################
#/proc/net/tcp 'st':
#/proc/net/tcp 'st':
#00  ERROR_STATUS
#01  TCP_ESTABLISHED
#02  TCP_SYN_SENT
#03  TCP_SYN_RECV
#04  TCP_FIN_WAIT1
#05  TCP_FIN_WAIT2
#06  TCP_TIME_WAIT
#07  TCP_CLOSE
#08  TCP_CLOSE_WAIT
#09  TCP_LAST_ACK
#0A  TCP_LISTEN
#0B  TCP_CLOSING
#######################

def check_tcp_file():
    tcp_files=['/proc/net/tcp','/proc/net/tcp6']
    exists_tcp_files=[]
    for f in tcp_files:
        if os.path.isfile(f):
            exists_tcp_files.append(f)
    return exists_tcp_files

def read_tcp_file(files):
    result = []
    fh = fileinput.input(files)
    for line in fh:
        if line and ( 'address' not in line ):
            result.append(line.split()[3])
    return result
        
def get_stat(stat_list):
    conn_types = {
            #'ERROR':'00',
            'ESTABLISHED':'01',
            #'SYN_SENT':'02',
            'SYN_RECV':'03',
            'FIN_WAIT1':'04',
            'FIN_WAIT2':'05',
            'TIME_WAIT':'06',
            #'CLOSE':'07',
            'CLOSE_WAIT':'08',
            'LAST_ACK':'09',
            #'LISTEN':'0A',
            #'CLOSING':'0B',
            }
    TOTAL={}
    TOTAL_CONN = 0 
    for k,v in conn_types.iteritems():
        c = stat_list.count(v)
        TOTAL_CONN += c
        TOTAL[k] = c
    TOTAL['TOTAL_CONN'] = TOTAL_CONN
    return TOTAL

def print_stat(stats):
    for k,v in stats.iteritems():
        print '%-11s %s' % (k,v)
    
def main():
    file_list = check_tcp_file()
    stat_list = read_tcp_file(file_list)
    stats=get_stat(stat_list)
    print_stat(stats)

if __name__ == '__main__':
    main()
        

