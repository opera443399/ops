@echo off
rem v1.0.2
color 2f
title Windows防火墙端口阻塞

set dport=8000
set direction=out
goto menu

:menu
set rule_name=block_tcp_%direction%_%dport%
echo.
echo        菜单：
echo            1. 增加这条规则:      
echo                                   [规则名：%rule_name%]
echo                                   [操作: 阻塞]
echo                                   [端口: %dport%]
echo                                   [方向: %direction%]
echo            2. 删除这条规则:   
echo                                   [规则名: %rule_name%]
echo            3. 设定新的端口和方向: 
echo                                   [默认值: 端口=8000, 方向=out]
echo            4. 显示这条规则:     
echo                                   [规则名: %rule_name%]
echo            5. 显示所有名称以block_tcp开头的规则:     
echo                                   [规则名: 以“block_tcp”开头]
echo            8. 帮助
echo            9. 菜单
echo            0. 退出
echo        _____________________________________________________________
echo        注1：选择数字，然后按回车；
echo.
goto start


:menu_help
echo.
echo  操作方法：
echo.
echo    →  按3（回车）：设定参数，示例如下，
echo                          端口[8000]=9001（回车）
echo                          方向[out]=（回车）（即默认的out）;
echo    →  按1（回车）：增加新规则“block_tcp_out_9001”到防火墙；
echo    →  按4（回车）：显示当前规则“block_tcp_out_9001”；
echo    →  按2（回车）：删除当前规则“block_tcp_out_9001”；
echo     重复上述步骤，操作新的规则；
echo    →  按5（回车）：显示所有名称以“block_tcp”开头的规则；
echo     删除前，请先确认当前设定的端口和方向。
echo.
goto start


:start
echo.
echo        [1(新增),2(删除),3(设定),4(显示),5(显示所有)]
echo        -------------------------------------------------------------
set choice=
set /p choice=请选择：
echo.
if /i "%choice%"=="" goto warn
if /i %choice%==1 goto rule_add
if /i %choice%==2 goto rule_del
if /i %choice%==3 goto setting
if /i %choice%==4 goto rule_show
if /i %choice%==5 goto rule_show_all
if /i %choice%==8 goto menu_help
if /i %choice%==9 goto menu
if /i %choice%==0 goto end



:warn
echo 警告！输入无效，请重新选择！& goto start

:rule_add
netsh advfirewall firewall add rule name="%rule_name%" dir=%direction% protocol=tcp remoteport=%dport% action=block
goto start


:rule_del
netsh advfirewall firewall del rule dir=%direction% name="%rule_name%"
goto start


:rule_show
netsh advfirewall firewall show rule dir=%direction% name="%rule_name%"
goto start


:rule_show_all
netsh advfirewall firewall show rule dir=%direction% name=all|findstr block_tcp
goto start


:setting
set dport=8000
set /p dport=端口[8000]:
echo %dport%|findstr "[^0-9]"
echo %dport%|findstr "[^0-9]" > nul && goto setting || goto setting_2



:setting_2
set direction=out
set /p direction=方向[out]:
echo %direction%|findstr "in out" > nul && goto menu || goto setting_2



:end
exit