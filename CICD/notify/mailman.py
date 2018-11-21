#!/usr/local/bin/python3
#
# via <Nosmo King> @ 20150814
# SSL only

'''

用法:
    mailman.py "to" "subject" "body" "attachments"

说明:
[-] 1个收件人:
        ./mailman.py 'a@example.com' "test subject" "simple test content"

[-] 多个收件人:
        ./mailman.py "a@example.com;b@example.com" "test again" "another simple test"

[-] 带附件:
        ./mailman.py 'c@example.com' 'test1' 'test att' '/tmp/a.log' '/tmp/1.log'

--

'''

from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email import encoders
import smtplib, os, sys, logging, base64

# 发件人
email_from_1 = {'smtp':'smtp.exmail.qq.com', 'account':'test@xxx.com', 'password':'xxx', 'nickname':'some_test', 'greeting':'Dear Sir'}
# 发件人，备用
email_from_2 = {'smtp':'smtp.126.com', 'account':'xxx@126.com', 'password':'xxx', 'nickname':'zbx_test_bak', 'greeting':'Dear Sir'}


# +---- logging ---+
logging_file = '/tmp/mailman.py.log'
logging.basicConfig(
    level = logging.DEBUG,
    format = '%(asctime)s [%(levelname)s]: %(message)s',
    filename = logging_file,
    filemode = 'a',
    )

def delivering(s_from, s_to):
    '''
    s_from: (smtp, account, password, nickname, greeting)
    s_to: (to, subject, body, attachments)
    '''

    #+---- logging ---+
    print("logging to", logging_file)
    logging.info('''\
Now delivering..
+------------------------------+
from:    {0} <{1}>
to:      {3}
subject: {4}
content:
>>
{2},

{5}
>>
attachments:
{6}
+------------------------------+
'''.format(s_from['nickname'], s_from['account'], s_from['greeting'],
            s_to['to'], s_to['subject'], s_to['body'], s_to['attachments']))

    # email header
    m = MIMEMultipart()
    m['From'] = '{0} <{1}>'.format(s_from['nickname'], s_from['account'])
    m['To'] = ';'.join(s_to['to'])
    m['Subject'] = s_to['subject']

    # email body
    content = MIMEText('''
{0},

{1}
    '''.format(s_from['greeting'], s_to['body']), 'plain', 'utf-8')
    m.attach(content)

    # email attachments
    for filename in s_to['attachments']:
        with open(filename, 'rb') as f:
            addon = MIMEBase('application', 'octet-stream')
            addon.set_payload(f.read())
            encoders.encode_base64(addon)
            addon.add_header('Content-Disposition', 'attachment; \
                    filename="{0}"'.format(os.path.basename(filename)))
            m.attach(addon)

    # send email
    svr = smtplib.SMTP(s_from['smtp'])
    try:
        #svr.connect(s_from['smtp']) # error accurred with python > 3.4  !
        svr.ehlo()
        svr.starttls()
        svr.ehlo()
        #svr.set_debuglevel(1)

        svr.login(s_from['account'], s_from['password'])
        svr.sendmail(s_from['account'], s_to['to'], m.as_string())
        retval = 0
    except KeyboardInterrupt:
        print('[*] operation aborted!')
        retval = -1
    except Exception as err:
        print('[*] delivering err: {0}'.format(err), file=sys.stderr)
        #+---- logging ---+
        logging.warning('delivering: {0}'.format(err))
        retval = -2
    finally:
        svr.quit()

    #+---- logging ---+
    logging.info("mailman code: {0}".format(retval))

    return retval

def usage():
    print(__doc__)
    sys.exit(2)

if __name__ == '__main__':
    if len(sys.argv) < 4:
        usage()

    email_to = {}
    email_to['to'] = sys.argv[1].split(';')
    email_to['subject'] = sys.argv[2]
    email_to['body'] = sys.argv[3]
    email_to['attachments'] = sys.argv[4:]

    try:
        retval = delivering(email_from_1, email_to)
        if retval < 0:
            tips = "try again, using backup account to deliver.."
            print(tips)
            #+---- logging ---+
            logging.info(tips)
            retval = delivering(email_from_2, email_to)
        msg = 'Mail delivering: '
        msg += 'Failed!' if retval else 'Successful!'
        print(msg)
        #+---- logging ---+
        logging.info(msg)
    except Exception as err:
        print('[*] main err: {0}'.format(err), file=sys.stderr)
        # logging
        logging.warning('{0}'.format(err))
