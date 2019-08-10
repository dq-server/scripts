#!/bin/bash

# USAGE: ./map_start.sh

# Start a static HTTP server for the Overviewer map.

cd ~/overviewer/map
screen -dm -L -S map sudo python3 -m http.server 80
