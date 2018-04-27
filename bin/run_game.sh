#!/bin/bash

echo "Start Master Server..."
./opengs_server -d -c ../conf/server_conf_master.xml

echo "Start DB Game Server..."
./opengs_server -d -c ../conf/server_conf_db_game.xml

echo "Start Bridge Server..."
./opengs_server -d -c ../conf/server_conf_bridge.xml

echo "Start Gate Server..."
./opengs_server -d -c ../conf/server_conf_gate.xml

echo "Start Scene Server..."
./opengs_server -d -c ../conf/server_conf_scene.xml
