#!/bin/bash

get_number_of_players () {
  (echo -e '\x06\x00\x00\x00\x00\x00\x01\x01\x00'; sleep 1) | nc -w 1 127.0.0.1 25565 | grep -Poa 'online":\K[0-9]+'
}

server_idle_minutes=0

while true; do
  if [ $( get_number_of_players ) == '0' ]; then
    ((server_idle_minutes++))
  else
    server_idle_minutes=0
  fi

  # Shut down after 15 minutes of inactivity.
  if [ $server_idle_minutes -gt 14 ]; then
    ./system_safe_shutdown.sh
    exit 0
  fi

  sleep 60
done
