#!/bin/bash

# Run the following locally before this script:

# cd <BACKUP WITH THE WORLD, WHITELIST, ETC>
# ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com mkdir minecraft && scp -r -i ~/.ssh/minecraft-ec2.pem ./* ec2-user@minecraft.deltaidea.com:~/minecraft/
#
# cd <DIRECTORY WITH START-STOP-BACKUP SCRIPTS>
# ssh -i ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com mkdir scripts && scp -r -i ~/.ssh/minecraft-ec2.pem ./* ec2-user@minecraft.deltaidea.com:~/scripts/
#
# scp -r -i ~/.ssh/minecraft-ec2.pem ~/.ssh/minecraft-ec2.pem ec2-user@minecraft.deltaidea.com:~/.ssh/

sudo yum update

mkdir minecraft-backups
mkdir overviewer
mkdir overviewer/map

cd minecraft
sudo yum install -y java-1.8.0
echo "eula=true" > eula.txt
wget -O server-1.14.4.jar "https://launcher.mojang.com/v1/objects/3dc3d84a581f14691199cf6831b71ed1296a9fdf/server.jar"

echo "0 * * * * ec2-user /home/ec2-user/scripts/minecraft_backup.sh" > crontab

sudo systemctl enable --now dyndns
sudo systemctl enable --now minecraft
sudo systemctl enable --now map
