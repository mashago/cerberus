#!/bin/bash

ps -ef | grep -n MassNetServer | awk '{print $3;}' | xargs kill -9
