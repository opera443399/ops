@echo off
color 2f
title 设置 IP 地址

:start
echo.
echo 【0. 退出】
echo.
set input=
set /p input=请输入IP：
if /i "%input%"=="" goto warn
if /i %input%==0 goto end
goto set_ip

:warn
echo 无效 & goto start

:set_ip
echo 请稍候...正在设置"本地连接"的IP地址
netsh interface ip set address name="本地连接" static %input% 255.255.255.0 192.168.100.1 1
if %ERRORLEVEL%==1 goto start
goto set_dns

:set_dns
echo 请稍候...正在设置"本地连接"的DNS地址
netsh interface ip set dns "本地连接" static 223.5.5.5 primary
goto start

:end
exit
@echo off