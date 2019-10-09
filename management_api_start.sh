#!/bin/bash

# USAGE: ./management_api_start.sh

# Requires sude to read /etc/letsencrypt/live/minecraft.deltaidea.com/*.pem
sudo screen -dmS management_api /home/ec2-user/scripts/management_api.py
sudo screen -S map -X logfile /home/ec2-user/management_api_process.log
sudo screen -S map -X log
