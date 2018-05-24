@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf
set SERVER_PKG_ID=1

@echo "Start DB Game Server1..."
start "db_game_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_db_game%SERVER_PKG_ID%_1.xml

@echo "Start DB Game Server2..."
start "db_game_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/conf_db_game%SERVER_PKG_ID%_2.xml

exit
