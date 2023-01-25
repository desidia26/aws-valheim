#!/bin/bash
set -e

wget https://desidia-valheim-mods.s3.amazonaws.com/mods.tar.gz
tar -zxvf mods.tar.gz -C /config/valheimplus/plugins
rm mods.tar.gz