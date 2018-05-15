@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf

@echo "Start DB Game Server..."
start "db_game_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_db_game.xml

exit
