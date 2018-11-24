@echo off

set BIN_NAME=cerberus.exe

C:\\Windows\\System32\\taskkill /F /im %BIN_NAME%

::TASKKILL /F /im opengs_server.exe
::TASKKILL /F /im opengs_client.exe

exit
