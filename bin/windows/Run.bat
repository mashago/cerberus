@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf

:: global login server pack
@echo "Start DB Login Server..."
start "db_login_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_db_login.xml

@echo "Start Login Server..."
start "login_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_login.xml

:: area server pack
@echo "Start Master Server..."
start "master_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_master.xml

@echo "Start DB Game Server..."
start "db_game_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_db_game.xml

@echo "Start Bridge Server..."
start "bridge_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_bridge.xml

@echo "Start Gate Server..."
start "gate_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_gate.xml

@echo "Start Scene Server..."
start "scene_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_scene.xml

:: client
::@echo "Start Lua Client..."
::start "client" %BIN_PATH%/opengs_client.exe %CONF_PATH%/client_conf.xml

exit
