#!/bin/bash

echo "Start Master Server..."
./MassNetServer -d -c ../conf/server_conf_master.xml

echo "Start DB Game Server..."
./MassNetServer -d -c ../conf/server_conf_db_game.xml

echo "Start Bridge Server..."
./MassNetServer -d -c ../conf/server_conf_bridge.xml

echo "Start Gate Server..."
./MassNetServer -d -c ../conf/server_conf_gate.xml

echo "Start Scene Server..."
./MassNetServer -d -c ../conf/server_conf_scene.xml
