@echo off

@echo "Start DB Login Server..."
start "db_login_svr" MassNetServer.exe "../conf/server_conf_db_login.xml"

@echo "Start Login Server..."
start "login_svr" MassNetServer.exe "../conf/server_conf_login.xml"

@echo "Start DB Game Server..."
start "db_game_svr" MassNetServer.exe "../conf/server_conf_db_game.xml"

@echo "Start Bridge Server..."
start "bridge_svr" MassNetServer.exe "../conf/server_conf_bridge.xml"

@echo "Start Router Server..."
start "router_svr" MassNetServer.exe "../conf/server_conf_router.xml"

@echo "Start Scene Server..."
start "scene_svr" MassNetServer.exe "../conf/server_conf_scene.xml"

@echo "Start Lua Client..."
start "client" MassNetClient.exe "../conf/client_conf.xml"

exit
