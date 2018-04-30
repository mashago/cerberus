#!/bin/bash

cd ../../

BIN_PATH=bin
CONF_PATH=conf

# global login server pack
echo "Start DB Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/server_conf_db_login.xml

echo "Start Login Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/server_conf_login.xml

# area server pack
echo "Start Master Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/server_conf_master.xml

echo "Start DB Game Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/server_conf_db_game.xml

echo "Start Bridge Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/server_conf_bridge.xml

echo "Start Gate Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/server_conf_gate.xml

echo "Start Scene Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/server_conf_scene.xml
