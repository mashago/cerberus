@echo off

@echo "Start Login Server..."
start "login_svr" MassNetServer.exe "../conf/server_conf_login.xml"

@echo "Start DB Server..."
start "db_svr" MassNetServer.exe "../conf/server_conf_db.xml"

@echo "Start Bridge Server..."
start "bridge_svr" MassNetServer.exe "../conf/server_conf_bridge.xml"

@echo "Start Router Server..."
start "router_svr" MassNetServer.exe "../conf/server_conf_router.xml"

@echo "Start Scene Server..."
start "scene_svr" MassNetServer.exe "../conf/server_conf_scene.xml"

@echo "Start Lua Client..."
start "client" MassNetClient.exe "../conf/client_conf.xml"

exit
