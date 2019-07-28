#!/bin/bash

# This script is used by ./map_render.py. Don't call this script directly!

echo "Building Overviewer from source..."
cd ~
sudo yum update -y
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum install -y gcc python36 python36-devel python36-pip python36-pillow python36-pillow-devel python36-numpy
wget -O overviewer-source.tar.gz https://github.com/overviewer/Minecraft-Overviewer/archive/1b85e478f55932aad8312fb49daa818e9b258b05.tar.gz
tar xvzf overviewer-source.tar.gz
rm overviewer-source.tar.gz
mv Minecraft-Overviewer* overviewer
cd ~/overviewer
python3 setup.py build

echo "Downloading the Minecraft client for textures..."
wget -O client.jar https://overviewer.org/textures/1.14.4

# These variables are used in config.py, see https://github.com/dq-server/overviewer-config
export MINECRAFT_WORLD_DIR="~/world-backup"
export MINECRAFT_MAP_DIR="~/overviewer/map"
export MINECRAFT_CLIENT_PATH="~/overviewer/client.jar"

echo "Downloading latest map config and icons from github.com/dq-server/overviewer-config..."
cd ~/overviewer
wget -O config.tar.gz https://github.com/dq-server/overviewer-config/tarball/master
tar xvzf config.tar.gz
rm config.tar.gz
mv deltaidea-overviewer-config* config

echo "Rendering the map..."
mv ~/previous-render ~/overviewer/map
cd ~/overviewer/config
python3 ../overviewer.py --config=config.py --processes 8
python3 ../overviewer.py --config=config.py --genpoi --skip-scan
cp -r icons/* ../map/icons
