#!/bin/bash

cd ../../

BIN_PATH=bin
CONF_PATH=conf
SERVER_PKG_ID=1

# global login server pack
echo "Start DB Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_db_login.xml

echo "Start Login Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_login.xml

# area server pack
echo "Start Master Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_master${SERVER_PKG_ID}_1.xml

echo "Start DB Game Server1..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_db_game${SERVER_PKG_ID}_1.xml

echo "Start Bridge Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_bridge${SERVER_PKG_ID}_1.xml

echo "Start Gate Server1..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_gate${SERVER_PKG_ID}_1.xml

echo "Start Gate Server2..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_gate${SERVER_PKG_ID}_2.xml

echo "Start Scene Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_scene${SERVER_PKG_ID}_1.xml
