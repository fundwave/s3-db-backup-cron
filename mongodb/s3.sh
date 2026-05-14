#!/bin/bash

#FILENAME=mongobackup-`date "+%Y-%m-%d-%H:%M:%S"`.tar.gz
FILENAME=mongobackup.tar.gz

tar czf ./mongoBackups/${FILENAME} ./mongoBackups/db/*

TAGGING_PARAM=""
if [[ "${ENABLE_S3_TAGS}" == "true" ]]; then
  TAGGING_PARAM="--tagging BACKUP_TYPE=MONGODB"
fi

test -f ./mongoBackups/${FILENAME} && aws s3api put-object --bucket $BUCKET_NAME --key "${S3_PREFIX}mongo-backup/$FILENAME" --body ./mongoBackups/${FILENAME} $TAGGING_PARAM
