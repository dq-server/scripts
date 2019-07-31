#!/bin/bash

# This script is used by ./map_render.py. Don't call this script directly!

cd ~
echo "Updating OS packages..."
sudo yum update -y > /dev/null
echo "Installing Python to compile Overviewer..."
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm > /dev/null
sudo yum install -y gcc python36 python36-devel python36-pip python36-pillow python36-pillow-devel python36-numpy > /dev/null
echo "Downloading Overviewer..."
wget -O overviewer-source.tar.gz https://github.com/overviewer/Minecraft-Overviewer/archive/1b85e478f55932aad8312fb49daa818e9b258b05.tar.gz > /dev/null
tar xvzf overviewer-source.tar.gz > /dev/null
rm overviewer-source.tar.gz > /dev/null
mv Minecraft-Overviewer* overviewer
cd ~/overviewer
echo "Compiling Overviewer..."
python3 setup.py build > /dev/null

echo "Downloading the Minecraft client for textures..."
wget -O client.jar https://overviewer.org/textures/1.14.4 > /dev/null

# These variables are used in config.py, see https://github.com/dq-server/overviewer-config
export MINECRAFT_WORLD_DIR="~/world-backup"
export MINECRAFT_MAP_DIR="~/overviewer/map"
export MINECRAFT_CLIENT_PATH="~/overviewer/client.jar"

echo "Downloading map config and icons from github.com/dq-server/overviewer-config..."
cd ~/overviewer
wget -O config.tar.gz https://github.com/dq-server/overviewer-config/tarball/master > /dev/null
tar xvzf config.tar.gz > /dev/null
rm config.tar.gz > /dev/null
mv dq-server-overviewer-config* config

echo "Rendering the map..."
mv ~/previous-render ~/overviewer/map
cd ~/overviewer/config
python3 ../overviewer.py --config=config.py --processes 8
python3 ../overviewer.py --config=config.py --genpoi --skip-scan
cp -r icons/* ../map/icons
