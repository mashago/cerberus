@echo off

cd ../../

set BIN_NAME=cerberus.exe
set BIN_PATH=bin
set CONF_PATH=config
set SERVER_PKG_ID=1

@echo "Start Sync DB..."
start "sync_db" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_sync_db%SERVER_PKG_ID%_1.lua

exit
