@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf

@echo "Start Bridge Server..."
start "bridge_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_bridge.xml

exit
