@echo off

@echo "Start Sync DB..."
start "sync_db" MassNetServer.exe "../conf/server_conf_sync_db.xml"

exit
