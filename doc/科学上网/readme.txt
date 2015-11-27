科学上网的方案教程
2015年1月22日 | 分类: 翻墙相关 | 标签: Linode, PPTP, shadowsocks, ssh, 科学上网
对于科学上网的方案，我建议是购买个便宜的VPS，这样系统自带了SSH，花几分钟就能安装上VPN（PPTP）和ShadowSocks，相当于花一笔钱买了3个不同功能的科学上网工具。另外VPN和SSH还可以开多个帐号，供好友使用，自己有空的话，还可以在上面搭个网站赚钱，可谓一举多得。

　　一、SSH上网方案

对于与SSH、VPN和ShadowSocks来说，SSH是最简单的，开通VPS后即可使用SSH帐号，服务器端不用设置。

SSH客户端有两种方案，一种是MyEnTunnel+PuTTY，一种是Bitvise SSH Client，MyEnTunnel支持自动登录，Bitvise SSH Client要自动登录需要添加参数-loginOnStartup，这样也可以自动登录。

在设置上，MyEnTunnel设置很简单，按照中文界面全填写即可。BitviseSSH设置相对比较麻烦，需要多加注意，“Login”页签Inital meth选password，然后写密码，“Option”页签选择Always reconnect automatically，On Login处不要选择Open Terminal和Open SFTP。“Services”页签选中Enable Socks Https Proxy Forwarding，在“Listen Port”这里，根据自身需求填写本地端口号（一般写1080即可）。

设置好了后，通过SSH上网的方案是，电脑启动组里添加MyEnTunnel或BitviseSSH，然后Dropbox等各类应用通过SOCK5连接，Chrome安装Proxy SwitchySharp或Proxy SwitchyOmega，代理服务器协议为SOCKS5，代理服务器地址127.0.0.1，代理端口1080，选自动切换模式，这样访问国内国外都是高速。对于Firefox用户来说可参考此文配置。

不过，SSH手机不太方便，如果单个IP地址用的多了有可能会被干扰，不要局域网很多人一起用，因此最好备用个VPN，或者选择ShadowSocks也可。

科学上网

二、ShadowSocks上网方案

ShadowSocks也是和SSHD类似的Socks5代理，是一个开源项目。ShadowSocks使用自定义协议，屏蔽和干扰就更为困难，因此相对来说稳定一些。

有网友做了个服务器端一键安装ShadowSocks的脚本，使用root用户登录，运行以下命令：

wget –no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev.sh

chmod +x shadowsocks-libev.sh

./shadowsocks-libev.sh 2>&1 | tee shadowsocks-libev.log

安装完成后，得到的服务器端口：8989，客户端端口：1080，密码为自己设定的密码。

ShadowSocks客户端可以点这里下载。安装完成后，配置客户端参数。

如果有智能路由器的话，在路由器上安装ShadowSocks，可以不需要在电脑安装客户端。

设置好了后，通过ShadowSocks上网的方案是，设置Shadowsocks为自动启动，其他设置和SSH几乎完全一样，在Dropbox等各类应用通过SOCK5连接，Chrome安装Proxy SwitchySharp或Proxy SwitchyOmega，代理服务器协议为SOCKS5，代理服务器地址127.0.0.1，代理端口1080，选自动切换模式。

ShadowSocks在iOS和Android上也有客户端，对于未越狱的iOS来说，ShadowSocks客户端并不支持全局代理。

三、VPN上网方案

对于未越狱的iOS来说，VPN是唯一支持全局代理的方式。

对于不同的操作系统，安装VPN方法也不太相同，下面是以CentOS6为例介绍一个VPN一键安装包。

首先确认服务器开通ppp和tun权限，如没有开通，请联系提供商来开通。

然后执行如下命令：

wget http://www.72yun.com/shell/vpn_centos6.sh

chmod a+x vpn_centos6.sh

bash vpn_centos6.sh

即可安装成功。

Windows电脑VPN设置

VPN没有客户端，在电脑上进行几个配置即可，打开控制面板、点击“查看网络状态和任务”进入网络和共享中心，点击“设置新的连接或网络”，选择“连接到工作区”，单击“下一步”按钮，在“您想如何连接？”选项中选择“使用我的虚拟专用网络（VPN）”，单击“下一步”按钮，公司名随便写，下一步“不拨初始连接”，接下来的主机名(地址)，输入主机地址后完成VPN创建，用户、密码选择为自己的帐号密码，然后点击“创建”按钮即可完成创建。

在“网络连接”里双击这个VPN，此时会弹出一个连接VPN的用户登录窗口，输入你的VPN帐号和密码，并点击“连接”。连接成功后会在屏幕右下角的任务栏会有一个VPN连接的图标，这时就可以用VPN连接来上网了。

iOS手机VPN设置

1，点击手机中的设置-通用-VPN-添加VPN设置；

2，添加VPN地址、VPN帐号和VPN密码；

3，点击存储，打开VPN开关，看到手机顶部显示有VPN字样就代表连上啦。

Android手机VPN设置

1，点击设置-更多；

2，点击VPN，选择右上角的加号添加VPN；

3，添加VPN地址、VPN帐号和VPN密码；名称随便填，服务器地址就是在VPN所找到的服务器主机名或者IP地址，填好后点保存；点击刚刚保存的VPN，弹出菜单，填写用户名和密码，勾选保存账户信息，点击连接；

4，左上角出现一个钥匙标记也表明vpn连接成功了，点击刚刚的vpn账号可以随时断开连接，长按则可以修改刚刚的设置。

至于VPS服务器的购买，有高帅富VPS之称的Linode，当然还有一些OpenVZ类型的屌丝VPS，不同价格的VPS提供流量不同，可以根据自己的具体需要来选择。

来源：http://www.williamlong.info/archives/4121.html