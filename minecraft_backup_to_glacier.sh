#!/bin/bash

screen -S minecraft -X stuff "/say Making a weekly cold storage backup...$(printf \\r)"

~/scripts/minecraft_backup.sh

BACKUP_NAME=dq-world-backup-`date +"%Y-%m-%d"`.tar.gz

mkdir ~/minecraft-backups/backup-glacier-staging
cd ~/minecraft-backups/backup-glacier-staging
cp -r ~/minecraft-backups/backup-0 ./world
rsync -avr --exclude="world" ~/minecraft/ .
tar -czvf $BACKUP_NAME ./*

aws glacier upload-archive --region eu-central-1 --account-id - --vault-name dq-minecraft --body $BACKUP_NAME

cd ~
rm -r ~/minecraft-backups/backup-glacier-staging

screen -S minecraft -X stuff "/say Weekly off-site backup complete.$(printf \\r)"
