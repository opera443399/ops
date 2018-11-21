@echo off
rem ## version 0.3 @ 2015/3/26
rem ## via NosmoKing
rem 简体中文
chcp 936 >nul
color fc
title 切换内外网的DNS【请以管理员身份运行】 ^| 多有打扰，敬请谅解 :-)

set s_Hour=%time:~0,2%
if /i %s_Hour% LSS 10 (
	color 2f
)

:menu
echo.
echo        菜单：
echo            1. 【内网】192.168.1.240
echo            2. 【外网】223.5.5.5
echo            3. 显示当前DNS
echo            9. 菜单
echo            0. 退出
echo.
echo        注：请输入菜单对应的数字，直接退出请按回车；
echo        ________________________________________________
echo.
goto start


:start
echo.
set choice=0
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
netsh interface ip set dns "本地连接" static 192.168.1.240 primary
netsh interface ip set dns "无线网络连接" static 192.168.1.240 primary
goto rule_show


:rule_20
netsh interface ip set dns "本地连接" static 223.5.5.5 primary
netsh interface ip set dns "无线网络连接" static 223.5.5.5 primary
goto rule_show


:rule_show
netsh interface ip show dnsservers "本地连接"
netsh interface ip show dnsservers "无线网络连接"
goto start


:end
exit
@echo on