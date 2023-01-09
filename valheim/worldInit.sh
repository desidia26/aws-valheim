#!/bin/bash
set -e
WORLD_BUCKET=$1
WORLD_NAME=$2
WORLD_DB=/config/worlds/${WORLD_NAME}.db
if [ ! -f "$WORLD_DB" ]; then
  echo "Downloading ${WORLD_BUCKET}${WORLD_DB}"
  aws s3 cp ${WORLD_BUCKET}${WORLD_DB} $WORLD_DB
fi

WORLD_FWL=/config/worlds/${WORLD_NAME}.fwl
if [ ! -f "$WORLD_FWL" ]; then
  echo "Downloading ${WORLD_BUCKET}${WORLD_FWL}"
  aws s3 cp ${WORLD_BUCKET}${WORLD_FWL} $WORLD_FWL
fi