@echo off

@echo "Start Master Server..."
start "master_svr" MassNetServer.exe "../conf/server_conf_master.xml"

@echo "Start DB Game Server..."
start "db_game_svr" MassNetServer.exe "../conf/server_conf_db_game.xml"

@echo "Start Bridge Server..."
start "bridge_svr" MassNetServer.exe "../conf/server_conf_bridge.xml"

@echo "Start Gate Server..."
start "gate_svr" MassNetServer.exe "../conf/server_conf_gate.xml"

@echo "Start Scene Server..."
start "scene_svr" MassNetServer.exe "../conf/server_conf_scene.xml"

exit
