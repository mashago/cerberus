@echo off

@echo "Start DB Login Server..."
start "db_login_svr" MassNetServer.exe "../conf/server_conf_db_login.xml"

@echo "Start Login Server..."
start "login_svr" MassNetServer.exe "../conf/server_conf_login.xml"

exit
