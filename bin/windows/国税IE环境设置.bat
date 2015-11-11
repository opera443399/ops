:: IE环境设置起

:: 添加网站 http://dzswj.szds.gov.cn 到信任站点
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\szds.gov.cn\dzswj" /v "http" /t REG_DWORD /d 2 /f

:: .NET Framework 设置
:: XAML 浏览器应用程序 开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2400" /t REG_DWORD /d 0 /f
:: XPS 文档 开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2401" /t REG_DWORD /d 0 /f
:: 松散 XAML 开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2402" /t REG_DWORD /d 0 /f




:: ActiveX控件和插件设置
:: ActiveX控件自动提示  关闭
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2201" /t REG_DWORD /d 3 /f

:: 对标记为可安全执行的ActiveX控制执行脚本   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1405" /t REG_DWORD /d 0 /f

:: 对未标记为可安全执行脚本的ActiveX控件初始化并执行   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1201" /t REG_DWORD /d 0 /f

:: 仅允许经过批准的域在未经提示的情况下使用ActiveX   关闭 0为关闭 3为启用
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "120B" /t REG_DWORD /d 0 /f

:: 二进制和脚本行为   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2000" /t REG_DWORD /d 0 /f

:: 下载未标签的ActiveX控件   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1004" /t REG_DWORD /d 0 /f

:: 下载已签名的ActiveX控件   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1001" /t REG_DWORD /d 0 /f

:: 允许Scriptlet   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1209" /t REG_DWORD /d 0 /f

:: 允许运行以前未使用的ActiveX控件而不提示   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1208" /t REG_DWORD /d 0 /f

:: 运行ActiveX控件和插件   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1200" /t REG_DWORD /d 0 /f


:: 脚本
:: Java小程序脚本 开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1402" /t REG_DWORD /d 0 /f

:: 活动脚本 开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1400" /t REG_DWORD /d 0 /f

:: XSS 筛选器 关闭
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1409" /t REG_DWORD /d 3 /f



:: 其它
:: 持续使用用户数据 开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1606" /t REG_DWORD /d 0 /f

:: 加载应用程序和不安全文件 开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1806" /t REG_DWORD /d 0 /f

:: 使用弹出窗口阻止程序 关闭
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1809" /t REG_DWORD /d 3 /f

:: 提交非加密表单数据 开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1601" /t REG_DWORD /d 0 /f

:: 通过域访问数据源 开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1406" /t REG_DWORD /d 0 /f

:: 显示混合内容   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1609" /t REG_DWORD /d 0 /f

:: 允许META REFRESH   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1608" /t REG_DWORD /d 0 /f

:: 允许 Microsoft 网页浏览器控件的脚本   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1206" /t REG_DWORD /d 0 /f

:: 允许网页使用活动内容受限协议   提示
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2300" /t REG_DWORD /d 1 /f

:: 允许网站打开没有地址或状态栏的窗口   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2104" /t REG_DWORD /d 0 /f

:: 在 IFRAME 中加载程序和文件   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1804" /t REG_DWORD /d 0 /f



:: 启用 .NET Framework 安装程序   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "2600" /t REG_DWORD /d 0 /f


:: 文件下载   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1803" /t REG_DWORD /d 0 /f

:: 字体下载   开启
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "1604" /t REG_DWORD /d 0 /f


:: 安全级别   自定义
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "CurrentLevel" /t REG_DWORD /d 0 /f


:: 对该区域中的所有站点要求服务器验证  67去勾  71勾上
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v "Flags" /t REG_DWORD /d 67 /f


:: 弹出窗口阻止程序  禁用
reg add "HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\New Windows" /v "PopupMgr" /t REG_SZ /d no /f


echo IE设置成功！任意键退出！
:: IE环境设置止

@echo off

for /f "tokens=1* delims=[" %%a in ('ver') do set b=%%b

set b=%b:* =%

::公共1

call:%b:~0,4%%PROCESSOR_ARCHITECTURE:~-1%

::公共2

pause&exit

:5.1.6

echo XP--32位

copy netsign.dll  c:\windows\system32
c:\windows\system32\regsvr32.exe /u c:\windows\system32\netsign.dll
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{62B938C4-4190-4F37-8CF0-A92B0A91CC77}" /f
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Ext\Settings\{62B938C4-4190-4F37-8CF0-A92B0A91CC77}" /f
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Ext\Stats\{62B938C4-4190-4F37-8CF0-A92B0A91CC77}" /f
copy netsign.dll  c:\windows\system32
c:\windows\system32\regsvr32.exe   c:\windows\system32\netsign.dll

goto end


:6.1.6
echo WIN7--32位

copy netsign.dll  c:\windows\system32
c:\windows\system32\regsvr32.exe /u c:\windows\system32\netsign.dll
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{62B938C4-4190-4F37-8CF0-A92B0A91CC77}" /f
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Ext\Settings\{62B938C4-4190-4F37-8CF0-A92B0A91CC77}" /f
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Ext\Stats\{62B938C4-4190-4F37-8CF0-A92B0A91CC77}" /f
copy netsign.dll  c:\windows\system32
c:\windows\system32\regsvr32.exe   c:\windows\system32\netsign.dll

goto end

:6.1.4
echo WIN7--64位

copy netsign.dll  c:\windows\sysWOW64
c:\windows\sysWOW64\regsvr32.exe /u c:\windows\sysWOW64\netsign.dll
del c:\windows\system32\netsign.dll
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{62B938C4-4190-4F37-8CF0-A92B0A91CC77}" /f
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Ext\Settings\{62B938C4-4190-4F37-8CF0-A92B0A91CC77}" /f
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Ext\Stats\{62B938C4-4190-4F37-8CF0-A92B0A91CC77}" /f
copy netsign.dll  c:\windows\sysWOW64
c:\windows\sysWOW64\regsvr32.exe   c:\windows\sysWOW64\netsign.dll

goto end

:end

