#!/bin/bash

# USAGE: ./minecraft_start.sh

# Start the Minecraft server in detached mode.

cd ~/minecraft
screen -dmS minecraft java -Xms3G -Xmx3G -jar server-1.15.2.jar
screen -S minecraft -X logfile ~/minecraft_process.log
screen -S minecraft -X log

sleep 60s
screen -dmS minecraft_watch_commands ~/scripts/minecraft_watch_commands.py
screen -S minecraft_watch_commands -X logfile ~/minecraft_watch_commands_process.log
screen -S minecraft_watch_commands -X log
