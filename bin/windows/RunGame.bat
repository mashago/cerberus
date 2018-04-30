@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf

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

exit
