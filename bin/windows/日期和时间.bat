@echo off
color 2f
title datetime example

:menu
echo.
echo        菜单：
echo            1. 显示
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
if /i %choice%==1 goto show
if /i %choice%==9 goto menu
if /i %choice%==0 goto end

:warn
echo 无效菜单,请重新选择！ & goto start

:show
set D=%date:~0,4%%date:~5,2%%date:~8,2%
if /i %time:~0,2% LSS 10 ( 
set T=0%time:~1,1%%time:~3,2%%time:~6,2%.%time:~9,2%
) else (
set T=%time:~0,2%%time:~3,2%%time:~6,2%.%time:~9,2%
)
echo %D%_%T%
goto start

:end
exit
@echo on