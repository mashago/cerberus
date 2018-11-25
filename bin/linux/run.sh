#!/bin/bash

cd ../../

rm -rf log/*.txt

BIN_NAME=cerberus
BIN_PATH=bin
CONF_PATH=conf
SERVER_PKG_ID=1

# global login server pack
echo "Start DB Server..."
$BIN_PATH/$BIN_NAME -d -c $CONF_PATH/conf_db_login.lua

echo "Start Login Server..."
$BIN_PATH/$BIN_NAME -d -c $CONF_PATH/conf_login.lua

# area server pack
echo "Start Master Server..."
$BIN_PATH/$BIN_NAME -d -c $CONF_PATH/conf_master${SERVER_PKG_ID}_1.lua

echo "Start DB Game Server1..."
$BIN_PATH/$BIN_NAME -d -c $CONF_PATH/conf_db_game${SERVER_PKG_ID}_1.lua

echo "Start Bridge Server..."
$BIN_PATH/$BIN_NAME -d -c $CONF_PATH/conf_bridge${SERVER_PKG_ID}_1.lua

echo "Start Gate Server1..."
$BIN_PATH/$BIN_NAME -d -c $CONF_PATH/conf_gate${SERVER_PKG_ID}_1.lua

echo "Start Gate Server2..."
$BIN_PATH/$BIN_NAME -d -c $CONF_PATH/conf_gate${SERVER_PKG_ID}_2.lua

echo "Start Scene Server..."
$BIN_PATH/$BIN_NAME -d -c $CONF_PATH/conf_scene${SERVER_PKG_ID}_1.lua
