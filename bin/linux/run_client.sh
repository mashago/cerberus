#!/bin/bash

cd ../../

BIN_NAME=cerberus
BIN_PATH=bin
CONF_PATH=conf

echo "Start Lua Client..."
$BIN_PATH/$BIN_NAME -c $CONF_PATH/conf_client.lua
