#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION=$(aws configure get region)
ECR_URL=$1
if [ -z "${ECR_URL}" ]; then
  echo "No ecr url provided!!!"
  exit 1
fi
TAG=$2
if [ -z "${TAG}" ]; then
  TAG=latest
fi
ECR_VALHEIM=${ECR_URL}:${TAG}
echo "building/pushing ${ECR_VALHEIM}"
./buildLocal.sh ${ECR_VALHEIM}
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
docker push ${ECR_VALHEIM}
