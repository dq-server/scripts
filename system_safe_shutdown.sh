#!/bin/bash

# USAGE: ./system_safe_shutdown.sh

# Stop the server services and then safely stop the instance.

sudo shutdown # Setting a timer for 60s before stopping the minecraft service because this script is a part of it.
sudo systemctl stop minecraft
