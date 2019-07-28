#!/bin/bash

# USAGE: ./minecraft_stop.sh

# Stop the Minecraft server if it's running using `screen`.

screen -S minecraft -X stuff "/stop$(printf \\r)"
sleep 10s # It can take some time to save the world and exit.
