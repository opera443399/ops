@echo off
rem ## version 1.9.3 @ 2015/4/17
rem ## via NosmoKing
rem 简体中文
chcp 936 >nul
color fc
title 【网络诊断工具】v1.9.3 ^| 多有打扰，敬请谅解 :-)

set s_URLS=tmpURLs.txt
set s_Date=%date:~5,2%%date:~8,2%
set s_Hour=%time:~0,2%

if /i %s_Hour% LSS 10 (
	set s_Hour=0%time:~1,1%
	color 2f
)

rem 要检查的网址列表如下：
rem -------------------------

echo www.qq.com >%s_URLS%
echo www.163.com >>%s_URLS%

rem -------------------------

echo.

goto MENU

rem ============================================================================================
:MENU
echo.
echo [+] 您好，请选择：
echo.
echo               [1] 快速（延迟）
echo              *[2] 推荐（延迟，解析）
echo               [3] 全面（延迟，解析，路由）
echo.
echo               [4] 拷贝日志
echo               [8] 说明
echo               [9] 菜单
echo               [0] 退出
echo.
set OPT=2
set /p OPT=请输入对应数字：
if %OPT%==1 goto FASTTEST
if %OPT%==2 goto DOTEST
if %OPT%==3 goto FULLTEST
if %OPT%==4 goto LOGFILE
if %OPT%==8 goto TEST
if %OPT%==9 goto MENU
if %OPT%==0 goto THEEND


rem [Simple Test]
:TEST
set s_Time=%s_Hour:~0,2%%time:~3,2%%time:~6,2%
set s_File=result_%s_Date%_%s_Time%.txt
echo 保存测试结果的文件名类似于这样的格式：
echo %s_File%
echo.
setlocal EnableDelayedExpansion
echo 测试的网址包括：
for /F %%i in (%s_URLS%) do (
    set www=%%i
    echo !www!
)
endlocal
echo.
pause
goto MENU


rem [Fast Test]
:FASTTEST
set s_Time=%s_Hour:~0,2%%time:~3,2%%time:~6,2%
set s_File=result1_%s_Date%_%s_Time%.txt
echo.
echo [+] 注：预计用时1-2分钟，结果将保存到：【 %s_File% 】
echo [-] 测试中，请稍等片刻..
echo.
echo. >> %s_File%
echo ---------开始时间：[%date%  %time%]  >> %s_File%
echo. >> %s_File%

for /F %%i in (%s_URLS%) do (
echo. >> %s_File%
echo ========================================== >> %s_File%
echo. >> %s_File%

echo.
echo [+] [1/1]
echo. >> %s_File%
echo [-]  运行：ping -n 20 %%i
echo $$ ping -n 20 %%i >> %s_File%
ping %%i -n 20 >> %s_File%
echo. >> %s_File%

echo. >> %s_File%
echo __________________________________________ >> %s_File%
echo. >> %s_File%
)

echo.
echo  测试结束。
echo. >> %s_File%
echo ---------结束时间：[%date%  %time%]  >> %s_File%
echo. >> %s_File%
goto EOF


rem [Do Test]
:DOTEST
set s_Time=%s_Hour:~0,2%%time:~3,2%%time:~6,2%
set s_File=result2_%s_Date%_%s_Time%.txt
echo.
echo [+] 注：预计用时2-3分钟，结果将保存到：【 %s_File% 】
echo [-] 测试中，请稍等片刻..
echo.
echo. >> %s_File%
echo ---------开始时间：[%date%  %time%]  >> %s_File%
echo. >> %s_File%

for /F %%i in (%s_URLS%) do (
echo. >> %s_File%
echo ========================================== >> %s_File%
echo. >> %s_File%

echo.
echo [+] [1/2]
echo. >> %s_File%
echo [-]  运行：ping -n 20 %%i
echo $$ ping -n 20 %%i >> %s_File%
ping %%i -n 20 >> %s_File%
echo. >> %s_File%

echo. 
echo [+] [2/2]
echo. >> %s_File%
echo [-]  运行：nslookup %%i
echo $$ nslookup %%i >> %s_File%
nslookup %%i >> %s_File%
echo. >> %s_File%


echo. >> %s_File%
echo __________________________________________ >> %s_File%
echo. >> %s_File%
)

echo.
echo  测试结束。
echo. >> %s_File%
echo ---------结束时间：[%date%  %time%]  >> %s_File%
echo. >> %s_File%
echo.
echo [+] 操作结束，请将生成的结果发给客服人员。
echo.

goto EOF


rem [Full Test]
:FULLTEST
set s_Time=%s_Hour:~0,2%%time:~3,2%%time:~6,2%
set s_File=result3_%s_Date%_%s_Time%.txt
echo.
echo [+] 注：预计用时3-5分钟，结果将保存到：【 %s_File% 】
echo [-] 测试中，请稍等片刻..
echo.
echo. >> %s_File%
echo ---------开始时间：[%date%  %time%]  >> %s_File%
echo. >> %s_File%

for /F %%i in (%s_URLS%) do (
echo. >> %s_File%
echo ========================================== >> %s_File%
echo. >> %s_File%

echo.
echo [+] [1/3]
echo. >> %s_File%
echo [-]  运行：ping -n 20 %%i
echo $$ ping -n 20 %%i >> %s_File%
ping %%i -n 20 >> %s_File%
echo. >> %s_File%

echo. 
echo [+] [2/3]
echo. >> %s_File%
echo [-]  运行：nslookup %%i
echo $$ nslookup %%i >> %s_File%
nslookup %%i >> %s_File%
echo. >> %s_File%

echo. 
echo [+] [3/3]
echo. >> %s_File%
echo [-]  运行：tracert -d %%i
echo $$ tracert -d %%i >> %s_File%
tracert -d %%i >> %s_File%
echo. >> %s_File%

echo. >> %s_File%
echo __________________________________________ >> %s_File%
echo. >> %s_File%
)

echo.
echo  测试结束。
echo. >> %s_File%
echo ---------结束时间：[%date%  %time%]  >> %s_File%
echo. >> %s_File%
echo.
echo [+] 操作结束，请将生成的结果发给客服人员。
echo.

goto EOF


rem ============================================================================================

:LOGFILE
rem today=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.%time:~9,2%
set today=%date:~5,2%-%date:~8,2%-%date:~0,4%
set targdir=日志文件
set logdir="%USERPROFILE%\Documents"

ver|find "5." >nul
if %errorlevel% == 0 (
rem win7以下版本的系统，我的文档路径需要查询，因为有许多改版的系统，修改了默认的路径
rem set logdir="%USERPROFILE%\My Documents"

for /F "tokens=1,2,*" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User shell Folders" ^| find /I "Personal"') do set logdir=%%k

)

echo.
echo [+] 复制用户的日志文件到文件夹【%targdir% 】中：
echo.
echo [-] 操作日期：%date%
echo     _______________________________
echo.

if not exist %targdir%\ (
echo [-] 新建：文件夹 “%targdir%”
mkdir %targdir%\
)

echo. 
echo [-] 查询：【我的文档】的路径为 %logdir%
echo.
echo     _______________________________
echo.
echo [+] 准备将最新的日志提取出来（今天改动过的文件）
rem 用xcopy替代copy
rem copy "%logdir%\logs\"*.log %targdir%\
echo [-] 复制-应用程序-常规日志：
xcopy /C /D:%today% /Y "%logdir%\logs\"*.log* %targdir%\

echo.
echo [*] 操作已完成。建议将日志文件压缩后发给客服人员。
echo     _______________________________

goto EOF


:EOF
echo.
pause
goto MENU

:THEEND
echo.
if exist %s_URLS% (
del %s_URLS%
)
exit


@echo on