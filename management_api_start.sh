#!/bin/bash

# USAGE: ./management_api_start.sh

# Requires sude to read /etc/letsencrypt/live/minecraft.deltaidea.com/*.pem
sudo screen -dmS management_api /home/ec2-user/scripts/management_api.py
