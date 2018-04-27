#!/bin/bash

ps -ef | grep -n opengs_server | awk -F":" '{print $2;}' | awk '{print $2}' | xargs kill -9
