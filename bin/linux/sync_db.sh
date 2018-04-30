#!/bin/bash

cd ../../

BIN_PATH=bin
CONF_PATH=conf

echo "Start Sync DB..."
$BIN_PATH/opengs_server -c $CONF_PATH/server_conf_sync_db.xml
