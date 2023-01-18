#!/bin/bash
set -e
aws lambda invoke --function-name $1 response.json