#!/bin/bash

# USAGE: ./management_server_start.sh

sudo screen -dm -S management_server /home/ec2-user/scripts/management_server.py
