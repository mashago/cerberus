@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf
set SERVER_PKG_ID=1

@echo "Start Gate Server1..."
start "gate_svr1" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_gate%SERVER_PKG_ID%_1.xml

@echo "Start Gate Server2..."
start "gate_svr2" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_gate%SERVER_PKG_ID%_2.xml

exit
