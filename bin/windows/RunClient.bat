@echo off

cd ../../

set BIN_NAME=cerberus.exe
set BIN_PATH=bin
set CONF_PATH=conf

:: client
@echo "Start Lua Client..."
start "client" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_client.lua

exit
