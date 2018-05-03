@echo off

cd ../../

set BIN_PATH=bin
set CONF_PATH=conf

:: client
@echo "Start Lua Client..."
start "client" %BIN_PATH%/opengs_client.exe %CONF_PATH%/client_conf.xml

exit
