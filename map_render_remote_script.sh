#!/bin/bash

# This script is used by ./map_render.py. Don't call this script directly!

echo "Renderer: Installing Overviewer..."

cd ~
# Updating OS packages
sudo yum update -y >/dev/null 2>&1
# Installing Python to compile Overviewer
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm >/dev/null 2>&1
sudo yum install -y gcc python36 python36-devel python36-pip python36-pillow python36-pillow-devel python36-numpy >/dev/null 2>&1
# Downloading Overviewer
wget -O overviewer-source.tar.gz https://github.com/overviewer/Minecraft-Overviewer/archive/1b85e478f55932aad8312fb49daa818e9b258b05.tar.gz >/dev/null 2>&1
tar xvzf overviewer-source.tar.gz >/dev/null 2>&1
rm overviewer-source.tar.gz >/dev/null 2>&1
mv Minecraft-Overviewer* overviewer
cd ~/overviewer
# Compiling Overviewer
python3 setup.py build >/dev/null 2>&1

echo "Renderer: Downloading Minecraft textures and our map config..."

# Downloading the Minecraft client for textures
wget -O client.jar https://overviewer.org/textures/1.14.4 >/dev/null 2>&1

# These variables are used in config.py, see https://github.com/dq-server/overviewer-config
export MINECRAFT_WORLD_DIR="~/world-backup"
export MINECRAFT_MAP_DIR="~/overviewer/map"
export MINECRAFT_CLIENT_PATH="~/overviewer/client.jar"

# Downloading map config and icons from https://github.com/dq-server/overviewer-config
cd ~/overviewer
wget -O config.tar.gz https://github.com/dq-server/overviewer-config/tarball/master >/dev/null 2>&1
tar xvzf config.tar.gz >/dev/null 2>&1
rm config.tar.gz >/dev/null 2>&1
mv dq-server-overviewer-config* config

echo "Renderer: Rendering the map, this takes 7-8 minutes..."

mkdir ~/overviewer/map
cd ~/overviewer/config
python3 ../overviewer.py --config=config.py --processes 96 >/dev/null 2>&1
python3 ../overviewer.py --config=config.py --genpoi >/dev/null 2>&1
cp -r icons/* ../map/icons
