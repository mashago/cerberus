#!/bin/bash

cd ../../

BIN_NAME=cerberus
BIN_PATH=bin
CONF_PATH=config

echo "Start Lua Client..."
$BIN_PATH/$BIN_NAME -c $CONF_PATH/conf_client.lua
