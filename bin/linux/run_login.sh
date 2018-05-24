#!/bin/bash

cd ../../

BIN_PATH=bin
CONF_PATH=conf

echo "Start DB Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_db_login.xml

echo "Start Login Server..."
$BIN_PATH/opengs_server -d -c $CONF_PATH/conf_login.xml
