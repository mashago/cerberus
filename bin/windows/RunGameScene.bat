@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf
set SERVER_PKG_ID=1

@echo "Start Scene Server..."
start "scene_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_scene%SERVER_PKG_ID%_1.xml

exit
