#!/bin/bash

# USAGE: ./minecraft_start.sh

# Start the Minecraft server in detached mode.

cd ~/minecraft && screen -d -m -S minecraft java -Xms1G -Xmx1G -jar server-1.14.4.jar
sleep 60s
screen -dm -L -S minecraft_watch_commands ~/scripts/minecraft_watch_commands.py
screen -dm -L -S minecraft_shutdown_when_idle ~/scripts/minecraft_shutdown_when_idle.sh
