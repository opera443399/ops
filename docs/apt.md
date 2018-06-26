# apt使用帮助
2018/6/26

有的朋友需要在 docker 镜像中安装其他软件包，但又不知道怎么办，这里以 jenkins 镜像为例说明：

### 查看 OS 版本
```
# cat /etc/issue
Debian GNU/Linux 9 \n \l

```

### 配置 apt 源
```bash
# cat <<'_EOF' >/etc/apt/sources.list
deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib
deb http://mirrors.aliyun.com/debian-security stretch/updates main
deb-src http://mirrors.aliyun.com/debian-security stretch/updates main
deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib
deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib
_EOF

# apt-get update
```

### 安装软件包
```
# apt-get install vim
```


### ZYXW、参考
1. [阿里巴巴镜像站点](https://opsx.alibaba.com/mirror)
