# 阿里云oss使用小结

### 命令行工具
```bash
##### 下载工具
~]# curl -o /usr/local/bin/ossutil http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/attach/50452/cn_zh/1516454058701/ossutil64?spm=a2c4g.11186623.2.6.yeyxEt


##### 配置 AK 等信息
~]# ossutil config -L ch

~]# cat ~/.ossutilconfig
[Credentials]
language=CH
endpoint=oss-cn-xxx.aliyuncs.com
accessKeyID=xxx
accessKeySecret=xxx

##### 查看帮助
~]# ossutil help cp |more

##### 列出
~]# ossutil ls oss://bucket01
LastModifiedTime                   Size(B)  StorageClass   ETAG     ObjectName
2018-03-06 16:49:41 +0800 CST            0      Standard   xxx      oss://bucket01/html/
2018-03-06 16:49:41 +0800 CST            0      Standard   xxx      oss://bucket01/html/dir1/
2018-03-06 16:49:41 +0800 CST            0      Standard   xxx      oss://bucket01/html/dir1/.gitkeep
2018-03-06 16:49:42 +0800 CST       368709      Standard   xxx      oss://bucket01/html/dir1/index.css
2018-03-06 16:49:41 +0800 CST          318      Standard   xxx      oss://bucket01/html/dir1/index.html
2018-03-06 16:49:42 +0800 CST      2532542      Standard   xxx      oss://bucket01/html/dir1/index.js
2018-03-06 16:49:41 +0800 CST            0      Standard   xxx      oss://bucket01/html/dir2/
Object Number is: 7
0.087204(s) elapsed


##### 下载
~]# ossutil cp -r -f -u oss://bucket01/html osstest/

~]# tree osstest/
osstest/
└── html
    ├── dir1
    │   ├── index.css
    │   ├── index.html
    │   └── index.js
    └── dir2

3 directories, 3 files

##### 上传
~]# ossutil cp -r -f -u osstest/html oss://bucket01/html
Succeed: Total num: 6, size: 2,901,569. OK num: 6(skip 6 files), Skip size: 2,901,569.
0.107582(s) elapsed

```
