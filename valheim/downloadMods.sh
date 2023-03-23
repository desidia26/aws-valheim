#!/bin/bash
set -e

wget https://desidia-valheim-mods.s3.amazonaws.com/mods.tar.gz
wget -O /opt/valheim/bepinex/BepInEx/config/valheim_plus.cfg https://desidia-valheim-plus-config.s3.amazonaws.com/valheim_plus.cfg
mkdir -p /config/BepInEx/plugins
tar -zxvf mods.tar.gz -C /opt/valheim/bepinex/BepInEx/plugins
rm mods.tar.gz