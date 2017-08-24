#!/bin/bash

echo "Start Login Server..."
./MassNetServer ../conf/server_conf_login.xml

echo "Start DB Server..."
./MassNetServer ../conf/server_conf_db.xml

echo "Start Bridge Server..."
./MassNetServer ../conf/server_conf_bridge.xml

echo "Start Router Server..."
./MassNetServer ../conf/server_conf_router.xml

echo "Start Scene Server..."
./MassNetServer ../conf/server_conf_scene.xml
