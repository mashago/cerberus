#!/bin/bash

echo "Start DB Login Server..."
./MassNetServer -d -c ../conf/server_conf_db_login.xml

echo "Start Login Server..."
./MassNetServer -d -c ../conf/server_conf_login.xml
