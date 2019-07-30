#!/bin/bash

# USAGE: ./map_stop.sh

# Stop the static HTTP server for the Overviewer map.

screen -S map -X quit
