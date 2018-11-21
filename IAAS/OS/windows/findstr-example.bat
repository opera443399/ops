@echo off
title 搜索
color f9
echo 检索*.log
echo 指定内容：“IM本次启用了第(6)个域名作为接入点”。
echo 格式如下：
echo 文件名:行数:内容
echo __________________________________
echo.
findstr /S /N "IM本次启用了第(6)个域名作为接入点" *.log
echo.
echo __________________________________
echo.
pause
@echo on