@echo off
rem v1.0.2
color 2f
title Windows Firewall Port Block

set dport=8000
set direction=out
goto menu

:menu
set rule_name=block_tcp_%direction%_%dport%
echo.
echo        Menu£º
echo            1. Add this rule:      
echo                                   [rule name£º%rule_name%]
echo                                   [action: block]
echo                                   [port: %dport%]
echo                                   [direction: %direction%]
echo            2. Delete this rule:   
echo                                   [rule name: %rule_name%]
echo            3. New Setting: 
echo                                   [default: port=8000, direction=out]
echo            4. Show this rule:     
echo                                   [rule name: %rule_name%]
echo            5. Show all rules begins with "block_tcp":     
echo                                   [rule name: block_tcp...like]
echo            8. Help
echo            9. Menu
echo            0. Quit
echo        _____________________________________________________________
echo        Tips£ºselect the number and then presss Enter£»
echo.
goto start


:menu_help
echo.
echo  HowTo£º
echo.
echo    ¡ú  Press 3 (Enter)£ºsetting, eg, 
echo                          port[8000]=9001(Enter)
echo                          direction[out]=(Enter)(which means out by default);
echo    ¡ú  Press 1 (Enter): add current rule "block_tcp_out_9001" to firewall;
echo    ¡ú  Press 4 (Enter): show current rule "block_tcp_out_9001" from firewall;
echo    ¡ú  Press 2 (Enter): delete current rule "block_tcp_out_9001" from firewall;
echo     repeat to operate more rules;
echo    ¡ú  Press 5 (Enter)£¬show all rules which name begins with "block_tcp";
echo     before you delete the rule, please check the current port and direction.
echo.
goto start


:start
echo.
echo        [1(Add),2(Del),3(Set),4(Show),5(Show All)]
echo        -------------------------------------------------------------
set choice=
set /p choice=Select£º
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
echo Warning! Input invalid, please re-select! & goto start

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
set /p dport=Port[8000]:
echo %dport%|findstr "[^0-9]"
echo %dport%|findstr "[^0-9]" > nul && goto setting || goto setting_2



:setting_2
set direction=out
set /p direction=Direction[out]:
echo %direction%|findstr "in out" > nul && goto menu || goto setting_2



:end
exit