@echo off
color 2f
title IP切换

:menu
echo.
echo        菜单：
echo            1. 192.168.10.120
echo            2. 192.168.20.120
echo            3. 显示当前IP。
echo            9. 菜单。
echo            0. 退出。
echo.
echo        注：请输入菜单对应的数字，直接退出请按回车；
echo        ________________________________________________
echo.
goto start


:start
echo.
set choice=
set /p choice=请输入：
if /i "%choice%"=="" goto warn
if /i %choice%==1 goto rule_10
if /i %choice%==2 goto rule_20
if /i %choice%==3 goto rule_show
if /i %choice%==9 goto menu
if /i %choice%==0 goto end

:warn
echo 无效菜单,请重新选择！ & goto start

:rule_10
echo 请稍候...
netsh interface ip set address name="本地连接" static 192.168.10.120 255.255.255.0 192.168.10.1 1
netsh interface ip set dns "本地连接" static 202.96.128.86 primary
goto start


:rule_20
netsh interface ip set address name="本地连接" static 192.168.20.120 255.255.255.0 192.168.20.1 1
netsh interface ip set dns "本地连接" static 202.96.128.86 primary
goto start


:rule_show
ipconfig /all|findstr IPv4|findstr 首选
goto start


:end
exit
@echo on