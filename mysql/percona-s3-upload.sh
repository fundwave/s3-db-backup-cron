#!/bin/bash

BACKUP_TYPE=${1:-'full'}  # 'full' or 'inc#'
BUCKET=${2}
FILE_PATH=${3:-'/opt/backup/percona/'}
FILENAME=${4:-'percona-backup'}

if [ "$BACKUP_TYPE" == "full" ]; then
    TAR_FILE="${FILENAME}-full.tar.gz"
else
    TAR_FILE="${FILENAME}-${BACKUP_TYPE}.tar.gz"
fi

if [ ! -f "${FILE_PATH}${TAR_FILE}" ]; then
    echo "Error: Backup file ${FILE_PATH}${TAR_FILE} not found." 1>&2
    exit 1
fi

echo "Uploading ${TAR_FILE} to S3..."
TAR_MD5_SUM=$(openssl md5 -binary "${FILE_PATH}${TAR_FILE}" | base64)

timestamp() {
  date  +"%Y-%m-%d_%H-%M-%S"
}

TIME_STAMP=$(timestamp)
S3_KEY="${S3_PREFIX}percona/${BACKUP_TYPE}/${TAR_FILE%.tar.gz}-${TIME_STAMP}.tar.gz"

aws s3api put-object \
    --bucket $BUCKET \
    --key "${S3_KEY}" \
    --body "${FILE_PATH}${TAR_FILE}" \
    --content-md5 $TAR_MD5_SUM \
    --metadata backuptype=${BACKUP_TYPE},timestamp=${TIME_STAMP}

echo "Percona backup uploaded successfully to s3://${BUCKET}/${S3_KEY}"
