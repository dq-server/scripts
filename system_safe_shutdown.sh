#!/bin/bash

# USAGE: ./system_safe_shutdown.sh

# Stop the server services and then safely stop the instance.

sudo systemctl stop minecraft
sudo systemctl stop map
sudo shutdown
