@echo off
color 2f
title ���� IP ��ַ

:start
echo.
echo ��0. �˳���
echo.
set input=
set /p input=������IP��
if /i "%input%"=="" goto warn
if /i %input%==0 goto end
goto set_ip

:warn
echo ��Ч & goto start

:set_ip
echo ���Ժ�...��������"��������"��IP��ַ
netsh interface ip set address name="��������" static %input% 255.255.255.0 192.168.100.1 1
if %ERRORLEVEL%==1 goto start
goto set_dns

:set_dns
echo ���Ժ�...��������"��������"��DNS��ַ
netsh interface ip set dns "��������" static 223.5.5.5 primary
goto start

:end
exit
@echo off
