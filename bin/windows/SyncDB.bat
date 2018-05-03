@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf

@echo "Start Sync DB..."
start "sync_db" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_sync_db.xml

exit
