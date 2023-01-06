#!/bin/bash
set -e

clean_up () {
    ARG=$?
    rm -rf ./config
    exit $ARG
} 
trap clean_up EXIT

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

IMAGE_NAME_AND_TAG=$1
if [ -z "${IMAGE_NAME_AND_TAG}" ]; then
  IMAGE_NAME_AND_TAG=desidia26/valheim:latest
fi

aws s3 cp s3://valheim-state/config ./config --recursive
WORLD_NAME=$(find ./config -name '*.db' -print | xargs -I {} basename {} .db)

docker build -t ${IMAGE_NAME_AND_TAG} \
  --no-cache \
  --build-arg WORLD_NAME=$WORLD_NAME \
  --progress plain .
