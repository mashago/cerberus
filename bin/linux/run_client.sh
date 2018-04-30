#!/bin/bash

cd ../../

BIN_PATH=bin
CONF_PATH=conf

echo "Start Lua Client..."
$BIN_PATH/opengs_client $CONF_PATH/client_conf.xml
