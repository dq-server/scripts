#!/bin/bash

# USAGE: ./map_start.sh

# Start a static HTTP server for the Overviewer map.

cd ~/overviewer/map
screen -dmS map sudo python3 -m http.server 80
screen -S map -X logfile ~/map_process.log
screen -S map -X log
