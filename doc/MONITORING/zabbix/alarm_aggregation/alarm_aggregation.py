#!/bin/env python
# coding=utf-8
# ----------------------------------
# @ 2017/2/22
# @ PC
# ----------------------------------
# [zabbix alarm aggregation], vers=1.1.2
#
##[requisition 1]: new action as given below
# Default subject: {EVENT.ID}_1
# Default message: triggervalue|{TRIGGER.VALUE}#hostname|{HOSTNAME1}#ipaddress|{IPADDRESS}#hostgroup|{TRIGGER.HOSTGROUP.NAME}#triggernseverity|{TRIGGER.NSEVERITY}#triggername|{TRIGGER.NAME}#triggerkey|{TRIGGER.KEY1}#triggeritems|{ITEM.NAME}#itemvalue|{ITEM.VALUE}#eventid|{EVENT.ID}
# Default subject: {EVENT.ID}_0
# Default message:  triggervalue|{TRIGGER.VALUE}#hostname|{HOSTNAME1}#ipaddress|{IPADDRESS}#hostgroup|{TRIGGER.HOSTGROUP.NAME}#triggernseverity|{TRIGGER.NSEVERITY}#triggername|{TRIGGER.NAME}#triggerkey|{TRIGGER.KEY1}#triggeritems|{ITEM.NAME}#itemvalue|{ITEM.VALUE}#eventid|{EVENT.ID}
#
##[requisition 2]: redis
# yum install redis -y && service redis start
# pip install redis


from __future__ import print_function
import MySQLdb, redis
import datetime, logging


ZBX_HOST = '127.0.0.1'
ZBX_DB = 'zabbix'
ZBX_DB_USER = 'zabbix'
ZBX_DB_PASS = 'pass'

ZBX_ALERT_RECIPIENTS = 'test_user@abc.com'


# +---- logging ---+
logging_file = '/tmp/alarm_aggregation.py.log'
logging.basicConfig(
    level = logging.DEBUG,
    format = '%(asctime)s [%(levelname)s]: %(message)s',
    filename = logging_file,
    filemode = 'a',
    )
debug = 1


def alert_by_email(triggername, status, content):
    import os
    users = ZBX_ALERT_RECIPIENTS
    subject = '[AA->{1}]{0}'.format(triggername, status)
    cmd = 'export LANG="en_US.UTF-8";/your/orignal/zabbix/alertscripts/zabbix_email "{0}" "{1}" "{2}"'.format(users, subject, content)
    if debug>1: logging.info('function [alert_by_email] run command: {0}'.format(cmd))
    ret = os.popen(cmd)
    if debug>1: logging.info('function [os.popen] return: {0}.'.format(ret.read()))


def handler_msgs(src, ok, reason):
    '''
        output
    '''
    list_of_hosts = ''
    list_of_hostgroups = ''
    triggername = ''

    status = 'PROBLEM'
    if ok: status = 'OK'

    if debug>1: logging.info("msgs:\n{star}\n{0}\n{star}\n".format(src, star='+'*12))
    for s in src:
        triggername = s['triggername']
        if s['hostname'] not in list_of_hosts:
            list_of_hosts += '{0}({1})\n'.format(s['hostname'], s['ipaddress'])
        if s['hostgroup'] not in list_of_hostgroups:
            list_of_hostgroups += '{0}\n'.format(s['hostgroup'])

    dt_now = datetime.datetime.now()

    content = '''
{s_status}: {s_triggername}\n
[Aggregation Reason]\n{s_reason}\n
[Hosts]\n{s_hosts}\n
[Host Groups]\n{s_hostgroups}\n
[Report Time]\n{s_dt}\n
'''.format(s_status=status, s_triggername=triggername, s_reason=reason,
        s_hosts=list_of_hosts, s_hostgroups=list_of_hostgroups, s_dt=dt_now)

    if debug: logging.info(content)
    #print(content)
    alert_by_email(triggername, status, content)


def check_msgs(src):
    '''
        classification
    '''
    cnt_triggerkey = {}
    status_problem = []
    status_ok = []

    for m in src:
        if m['triggerkey'] not in cnt_triggerkey:
            cnt_triggerkey[m['triggerkey']] = []
        cnt_triggerkey[m['triggerkey']].append(m)

    for k,v in  cnt_triggerkey.items():
        print("{star}\ntriggerkey={0}, count={1}".format(k, len(v), star='+'*12))
        if debug: logging.info("{star}\ntriggerkey={0}, count={1}".format(k, len(v), star='+'*12))

        for n in v:
            if n['triggervalue'] == '1':
                status_problem.append(n)
            else:
                status_ok.append(n)
        print("len(status_problem)={0}, len(status_ok)={1}\n{star}\n".format(len(status_problem), len(status_ok), star='-'*6))
        if debug: logging.info("len(status_problem)={0}, len(status_ok)={1}\n{star}\n".format(len(status_problem), len(status_ok), star='-'*6))

        if len(status_problem) > 5:
            handler_msgs(status_problem, False, 'trigger occurred {0} times.'.format(len(status_problem)))
        elif 3 < len(status_problem) <= 5:
            handler_msgs(status_problem, False, 'trigger occurred {0} times.'.format(len(status_problem)))
             

        if len(status_ok) > 5:
            handler_msgs(status_ok, True, 'trigger occurred {0} times.'.format(len(status_problem)))
        elif 3 < len(status_problem) <= 5:
            handler_msgs(status_ok, True, 'trigger occurred {0} times.'.format(len(status_problem)))


def trans_data_to_dict(data):
    '''
        return msgs as dict
    '''
    msgs = {}
    each_line = data.split('#')
    for i in each_line:
        k, v = i.split('|')
        msgs[k] = v
    if debug: logging.info('msgs: {0}'.format(msgs))

    return msgs



def aggregation(action_id, r):
    '''
        main
    '''
    event_ids = r.keys()
    r_size = r.dbsize()
    dt_now = datetime.datetime.now()
    if not r_size:
        print('{0}, No record found!'.format(dt_now))
        if debug: logging.info('{0}, No record found!'.format(dt_now))

        return 

    all_msgs = []
    for event_id in event_ids:
        message = r.get(event_id) 
        ret = trans_data_to_dict(message)
        if debug>1: logging.info('function [trans_data_to_dict] result: {0}'.format(ret))
        all_msgs.append(ret)

    if all_msgs:
        check_msgs(all_msgs)
        if debug>2: logging.info('[len(all_msgs)={0}]: \n{1}\n'.format(len(all_msgs), all_msgs))

        print('redis get_and_removed: {0} keys'.format(r_size))
        if debug: logging.info('redis get_and_removed: {0} keys'.format(r_size))
        for e in event_ids:
            ret = r.delete(e)
            if debug>1: logging.info('redis delete key: {0}, result: {0}'.format(e, ret))



def test_run(action_id, r, ts):
    '''
        test
    '''
    try:
        conn = MySQLdb.connect(host=ZBX_HOST,
                            user=ZBX_DB_USER,
                            passwd=ZBX_DB_PASS,
                            db=ZBX_DB,
                            port=3306)
        cursor = conn.cursor()
        sql = 'set names utf8'
        cursor.execute(sql);

        sql = "select subject, message from alerts where actionid='{0}' and clock>'{1}';".format(action_id, ts)
        cursor.execute(sql)

        ret = cursor.fetchall()
        if debug>2: logging.info('sql result: {0}'.format(ret))
        cnt = 0
        for id in ret:
            if debug>1: logging.info('redis set: {0}->{1}'.format(id[0], id[1]))
            ret = r.set(id[0], id[1])
            if debug>1: logging.info('redis result: {0}'.format(ret))
            cnt += 1
        if debug>1: logging.info('push to redis count: {0}'.format(cnt))

    except MySQLdb.Error as e:
        print("[E] {0}".format(e))

    finally:
        if cursor: cursor.close()
        if conn: conn.close()


if __name__ == "__main__":
    '''
        alarm aggregation for zbx
    '''
    pool = redis.ConnectionPool(host='127.0.0.1', port=6379)
    r = redis.StrictRedis(connection_pool=pool)
    #on linux shell:
    #while true;do python -c "import redis;pool = redis.ConnectionPool(host='127.0.0.1', port=6379);r = redis.StrictRedis(connection_pool=pool);print r.keys()";sleep 1s;done

    #normal zbx action
    import sys
    if len(sys.argv) == 4:
        username, subject, content = sys.argv[1:]
        if debug>1: logging.info('argv: {0}'.format(sys.argv[1:]))

        ret = r.set(subject, content)
        if debug: logging.info('redis result: {0}'.format(ret))

    #main
    else:
        #push test data(depends on timestamp as given) to redis
        #import time; ts = int(time.time()-3600); test_run('14', r, ts)

        #[NOTICE: actionid=14 in this environment.]
        aggregation('14', r)

