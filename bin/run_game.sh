#!/bin/bash

echo "Start DB Game Server..."
./MassNetServer -d -c ../conf/server_conf_db_game.xml

echo "Start Bridge Server..."
./MassNetServer -d -c ../conf/server_conf_bridge.xml

echo "Start Router Server..."
./MassNetServer -d -c ../conf/server_conf_router.xml

echo "Start Scene Server..."
./MassNetServer -d -c ../conf/server_conf_scene.xml
