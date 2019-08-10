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
sudo yum install -y java-1.8.0 nc epel-release certbot

mkdir minecraft-backups
mkdir overviewer
mkdir overviewer/map

cd minecraft
echo "eula=true" > eula.txt
wget -O server-1.14.4.jar "https://launcher.mojang.com/v1/objects/3dc3d84a581f14691199cf6831b71ed1296a9fdf/server.jar"

# IMPORTANT! This line requires interaction. It asks for email, etc.
sudo certbot certonly --standalone

echo "0 * * * * ec2-user /home/ec2-user/scripts/minecraft_backup.sh" > crontab
echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew" | sudo tee -a /etc/crontab > /dev/null

sudo systemctl enable --now dyndns
sudo systemctl enable --now minecraft
sudo systemctl enable --now map
sudo systemctl enable --now management_server
