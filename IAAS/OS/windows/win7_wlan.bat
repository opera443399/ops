@echo off
color 2f
title Windows 7 WLAN

:menu
echo.
echo        菜单：
echo            1. 设定
echo            2. 打开
echo            3. 关闭
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
if /i %choice%==1 goto set
if /i %choice%==2 goto open
if /i %choice%==3 goto close
if /i %choice%==9 goto menu
if /i %choice%==0 goto end

:warn
echo 无效菜单,请重新选择！ & goto start

:set
netsh wlan set hostednetwork mode=allow ssid="pcwlan" key="123456"
goto start

:open
netsh wlan start hostednetwork
goto start

:close
netsh wlan stop hostednetwork
goto start

:end
exit
@echo on