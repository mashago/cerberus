#!/bin/bash

echo "Start DB Login Server..."
./opengs_server -d -c ../conf/server_conf_db_login.xml

echo "Start Login Server..."
./opengs_server -d -c ../conf/server_conf_login.xml
