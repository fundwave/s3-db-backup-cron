#!/bin/bash

#FILENAME=mongobackup-`date "+%Y-%m-%d-%H:%M:%S"`.tar.gz
FILENAME=mongobackup.tar.gz

tar czf ./mongoBackups/${FILENAME} ./mongoBackups/db/* || { echo "Compression failed" 1>&2; exit 1; }

aws s3api put-object --bucket $BUCKET_NAME --key "${S3_PREFIX}mongo-backup/$FILENAME" --body ./mongoBackups/${FILENAME} ${S3_TAGGING:+--tagging "$S3_TAGGING"} || { echo "Upload failed" 1>&2; exit 1; }
