#!/bin/bash

# USAGE: ./minecraft_restore.sh <number between 0-9>

# Restore the world from a specified backup.

BACKUP=~/minecraft-backups/backup-$1

if [ ! -d "$BACKUP" ]; then
  echo "ERROR! \"$BACKUP\" doesn't exist!"
  exit 1
fi

echo "Stopping the Minecraft server..."
~/scripts/minecraft_stop.sh

echo "Thanos snapping the world..."
rm -r ~/minecraft/world
echo "Restoring from \"$BACKUP\"..."
cp -r "$BACKUP" ~/minecraft/world

echo "Starting the Minecraft server..."
~/scripts/minecraft_start.sh
