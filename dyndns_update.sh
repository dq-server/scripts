#!/bin/bash

# USAGE: ./dyndns_update.sh

# Bind minecraft.deltaidea.com to a new IP. The domain is parked at Namecheap, they provide DynDNS for free.
# Our Minecraft server is hosted on AWS, so the public IP changes after stopping the instance.

PUBLIC_IP=`curl ipecho.net/plain`
PASSWORD=`cat ~/.dyndns_password`

sleep 10s # dyndns.service is started by the OS before the network interface is configured.
curl "https://dynamicdns.park-your-domain.com/update?host=minecraft&domain=deltaidea.com&password=$PASSWORD&ip=$PUBLIC_IP"
