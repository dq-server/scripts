#!/bin/bash

# USAGE: ./map_start.sh

# Start a static HTTP server for the Overviewer map.

cd ~/overviewer/map
screen -d -m -S map sudo python3 -m http.server 80 > map-server.log
