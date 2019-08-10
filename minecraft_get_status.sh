#!/bin/bash

echo -e '\x06\x00\x00\x00\x00\x00\x01\x01\x00' | nc -w 1 127.0.0.1 25565 | grep -Poa '{.*' | tr -d '\r'
