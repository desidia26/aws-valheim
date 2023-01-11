#!/bin/bash

BACKUP_PATH=$1
WORLD_BUCKET=$2
FILE_NAME=$(basename -- "$BACKUP_PATH")
aws s3 cp $BACKUP_PATH ${WORLD_BUCKET}/backups/${FILE_NAME}
notifyDiscord "Backup $FILE_NAME saved to s3!"