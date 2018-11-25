@echo off

cd ../../

set BIN_NAME=cerberus.exe
set BIN_PATH=bin
set CONF_PATH=conf
set SERVER_PKG_ID=1

:: global login server pack
@echo "Start DB Login Server..."
start "db_login_svr" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_db_login.lua

@echo "Start Login Server..."
start "login_svr" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_login.lua

:: area server pack
@echo "Start Master Server..."
start "master_svr" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_master%SERVER_PKG_ID%_1.lua

@echo "Start DB Game Server1..."
start "db_game_svr1" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_db_game%SERVER_PKG_ID%_1.lua

@echo "Start DB Game Server2..."
start "db_game_svr1" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_db_game%SERVER_PKG_ID%_2.lua

@echo "Start Bridge Server..."
start "bridge_svr" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_bridge%SERVER_PKG_ID%_1.lua

@echo "Start Gate Server1..."
start "gate_svr1" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_gate%SERVER_PKG_ID%_1.lua

@echo "Start Gate Server2..."
start "gate_svr2" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_gate%SERVER_PKG_ID%_2.lua

@echo "Start Scene Server..."
start "scene_svr" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_scene%SERVER_PKG_ID%_1.lua

:: client
::@echo "Start Lua Client..."
::start "client" %BIN_PATH%/%BIN_NAME% %CONF_PATH%/conf_client.lua

exit
