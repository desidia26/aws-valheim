#!/bin/bash
set -e

curl -sfSL -X POST -H "Content-Type: application/json" -d "{\"username\":\"Valheim-Bot\",\"content\":\"$1\"}" "$DISCORD_WEBHOOK"