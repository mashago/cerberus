@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf
set SERVER_PKG_ID=1

@echo "Start Sync DB..."
start "sync_db" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_sync_db%SERVER_PKG_ID%_1.xml

exit
