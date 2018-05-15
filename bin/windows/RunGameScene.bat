@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf

@echo "Start Scene Server..."
start "scene_svr" %BIN_PATH%/opengs_server.exe %CONF_PATH%/server_conf_scene.xml

exit
