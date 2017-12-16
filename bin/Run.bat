@echo off

:: global login server pack
@echo "Start DB Login Server..."
start "db_login_svr" MassNetServer.exe "../conf/server_conf_db_login.xml"

@echo "Start Login Server..."
start "login_svr" MassNetServer.exe "../conf/server_conf_login.xml"


:: global cross server pack
:: @echo "Start Cross Scene Server..."
:: start "cross_scene_svr" MassNetServer.exe "../conf/server_conf_cross_scene.xml"


:: area server pack
@echo "Start DB Game Server..."
start "db_game_svr" MassNetServer.exe "../conf/server_conf_db_game.xml"

@echo "Start Bridge Server..."
start "bridge_svr" MassNetServer.exe "../conf/server_conf_bridge.xml"

@echo "Start Router Server..."
start "router_svr" MassNetServer.exe "../conf/server_conf_router.xml"

@echo "Start Router Server2..."
start "router_svr2" MassNetServer.exe "../conf/server_conf_router2.xml"

@echo "Start Scene Server..."
start "scene_svr" MassNetServer.exe "../conf/server_conf_scene.xml"

:: client
@echo "Start Lua Client..."
start "client" MassNetClient.exe "../conf/client_conf.xml"

exit
