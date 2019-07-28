#!/bin/bash

# USAGE: ./minecraft_backup.sh

# Tell the Minecraft server to save the world and then copy it.

echo "Saving the world..."
screen -S minecraft -X stuff "/save-all$(printf \\r)"
sleep 2s
screen -S minecraft -X stuff "/save-off$(printf \\r)"
sleep 2s

# Rotate 10 backups by deleting the oldest one and shifting the rest.
echo "Rotating previous backups..."
rm -r ~/minecraft-backups/backup-9/ 2> /dev/null
mv ~/minecraft-backups/backup-8/ ~/minecraft-backups/backup-9/ 2> /dev/null
mv ~/minecraft-backups/backup-7/ ~/minecraft-backups/backup-8/ 2> /dev/null
mv ~/minecraft-backups/backup-6/ ~/minecraft-backups/backup-7/ 2> /dev/null
mv ~/minecraft-backups/backup-5/ ~/minecraft-backups/backup-6/ 2> /dev/null
mv ~/minecraft-backups/backup-4/ ~/minecraft-backups/backup-5/ 2> /dev/null
mv ~/minecraft-backups/backup-3/ ~/minecraft-backups/backup-4/ 2> /dev/null
mv ~/minecraft-backups/backup-2/ ~/minecraft-backups/backup-3/ 2> /dev/null
mv ~/minecraft-backups/backup-1/ ~/minecraft-backups/backup-2/ 2> /dev/null
mv ~/minecraft-backups/backup-0/ ~/minecraft-backups/backup-1/ 2> /dev/null
echo "Saving a new backup..."
cp -r ~/minecraft/world ~/minecraft-backups/backup-0

echo "Enabling autosave again on the Minecraft server..."
screen -S minecraft -X stuff "/save-on$(printf \\r)"
sleep 2s
