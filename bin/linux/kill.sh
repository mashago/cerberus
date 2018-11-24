#!/bin/bash

BIN_NAME=cerberus
ps -ef | grep -n $BIN_NAME | awk -F":" '{print $2;}' | awk '{print $2}' | xargs kill -9
