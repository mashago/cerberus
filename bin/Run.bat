@echo off

@echo "Start Login Server..."
start "login_svr" ServerMt.exe "../conf/server_conf_login.xml"

@echo "Start DB Server..."
start "db_svr" ServerMt.exe "../conf/server_conf_db.xml"

@echo "Start Bridge Server..."
start "bridge_svr" ServerMt.exe "../conf/server_conf_bridge.xml"

@echo "Start Router Server..."
start "router_svr" ServerMt.exe "../conf/server_conf_router.xml"

@echo "Start Scene Server..."
start "scene_svr" ServerMt.exe "../conf/server_conf_scene.xml"

exit
