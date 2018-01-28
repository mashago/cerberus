#!/bin/bash

ps -ef | grep -n MassNetServer | awk -F":" '{print $2;}' | awk '{print $2}' | xargs kill -9
