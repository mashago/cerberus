@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf
set SERVER_PKG_ID=1

@echo "Start Master Server..."
start "master_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_master%SERVER_PKG_ID%_1.xml

@echo "Start DB Game Server1..."
start "db_game_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_db_game%SERVER_PKG_ID%_1.xml

@echo "Start DB Game Server1..."
start "db_game_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_db_game%SERVER_PKG_ID%_2.xml

@echo "Start Bridge Server..."
start "bridge_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_bridge%SERVER_PKG_ID%_1.xml

@echo "Start Gate Server1..."
start "gate_svr1" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_gate%SERVER_PKG_ID%_1.xml

@echo "Start Gate Server2..."
start "gate_svr2" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_gate%SERVER_PKG_ID%_2.xml

@echo "Start Scene Server..."
start "scene_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_scene%SERVER_PKG_ID%_1.xml

exit
