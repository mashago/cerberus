@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf

@echo "Start Master Server..."
start "master_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_master.xml

exit
