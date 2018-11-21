# 非法链接，只允许来自 123.232.23.245 的访问
2018/7/27

> 吐槽自己：我这种人啊，，水平太烂，，中午手工尝试了半天也不知道咋搞，，，还是得靠搜索引擎查找报错关键字来交作业啊

**注意：** 请参考 `payload.py`，，我只是在引文中原作者的基础上，简单修正了下代码复用和增加对 ascii code 为空格的判断。

### 用法

先解决依赖：
```bash
$ sudo easy_install pip
$ sudo pip install requests

##### pyv8
$ wget https://raw.githubusercontent.com/emmetio/pyv8-binaries/master/pyv8-osx.zip
##### 解压后有2个文件：
$ ls
PyV8.py  _PyV8.so
##### 拷贝到 py 包目录：
$ pip --version
pip 18.0 from /Library/Python/2.7/site-packages/pip-18.0-py2.7.egg/pip (python 2.7)
##### 拷贝到 `/Library/Python/2.7/site-packages/` 下即可

```

修改代码中 payload 来获取不同的内容，然后运行：
```bash
$ python payload.py
```




### ZYXW、参考
1. [DDCTF WEB1 数据库的秘密 Writeup](https://www.inorijam.com/index.php/ddctf-web1-writeup.html)
