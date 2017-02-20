#!/bin/bash

# The CI build variables

export IMAGE_REF=0xx0x0xx0000000xx0xxxx00000x000xx00xx00x
export DEPLOY_ENV=stage

export AWS_ECR_REGION=eu-west-1
export AWS_ECR_REPO=000000000000.dkr.ecr.eu-west-1.amazonaws.com/
export AWS_ECC_REGION=eu-central-1
export AWS_ACCOUNT_ID=000000000000
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxx

# The application variables

export STAGE_DB_HOST=xxx-xxxxx.xxxxxxxxxx.xxxxxx.xxx.xxxxxxxxx.xxx
export STAGE_DB_PORT=0000
export STAGE_DB_NAME=xxxxxxxx
export STAGE_DB_USER=xxxxxxxx
export STAGE_DB_PASS=xxxxxxxxxxxxxxxxxxxxxxxxxx

export STAGE_REDIS_HOST=xxx-xxxxx.xxxxxx.xxx.xxxxx.xxxxxxxxx.xxx
export STAGE_REDIS_PORT=0000
export STAGE_REDIS_DB=0

export STAGE_SMTP_HOST=xxxxx-xxxx.xx-xxxx-x.xxxxxxxxx.xxx
export STAGE_SMTP_PORT=0000
export STAGE_SMTP_USER=xxxxxxxxxxxxxxxxxxxx
export STAGE_SMTP_PASS=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

export STAGE_BUCKET_NAME=xxx-xxxxx

export STAGE_APP_HOST=xxx-xxxxx-xxxxxxxxx.xx-xxxx-x.xxx.xxxxxxxxx.xxx
export STAGE_APP_ASSET_HOST=xxxxxxxxxxxxxx.xxxxxxxxxx.xxx
export STAGE_APP_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
