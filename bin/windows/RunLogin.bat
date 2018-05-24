@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf

@echo "Start DB Login Server..."
start "db_login_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_db_login.xml

@echo "Start Login Server..."
start "login_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_login.xml

exit
