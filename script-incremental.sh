#!/bin/bash

SERVER=${SERVER:-"db"}
CURRENT_DIR=$(dirname "$0")

BACKUPS_DISABLED=${BACKUPS_DISABLED:-"false"}

if [ -z ${BUCKET_NAME} ] ; then
  echo "BUCKET_NAME is not set, exiting." 1>&2;
  exit 1;
fi

if [ -z ${S3_PREFIX} ] ; then
  echo "S3_PREFIX is not set, backups will be stored in the root of the bucket."
elif [[ -n "$S3_PREFIX" && "${S3_PREFIX: -1}" != "/" ]]; then
  S3_PREFIX="${S3_PREFIX}/"
else
  echo "S3_PREFIX is set to ${S3_PREFIX}";
fi

if [ $BACKUPS_DISABLED == 'TRUE' ] || [ $BACKUPS_DISABLED == 'true' ]
then
  echo "No backups since BACKUPS_DISABLED is set to $BACKUPS_DISABLED ."
  exit 0
fi

if [ -n "${DB_NAME}" ] && [ -n "${SERVER}" ] ; then 

  echo "MYSQL INCREMENTAL BACKUP (Percona)"
  echo "==================================="

  # Determine the incremental number
  PERCONA_PATH="/opt/backup/percona/"
  LAST_INC=0
  if ls "${PERCONA_PATH}"inc* 1> /dev/null 2>&1; then
      LAST_INC=$(ls -d "${PERCONA_PATH}"inc* | sed 's/.*inc//' | sort -n | tail -1)
  fi
  NEXT_INC=$((LAST_INC + 1))

  echo "Step 1. Percona Incremental Backup (inc${NEXT_INC})"
  "$CURRENT_DIR/mysql/percona-incremental-backup.sh" "$MYSQL_USERNAME" "$MYSQL_PASSWORD" "$SERVER" "$DB_NAME" "percona-backup" "/opt/backup/percona/"
  echo "Step 2. Saving Percona incremental backup to S3"
  "$CURRENT_DIR/mysql/percona-s3-upload.sh" "inc${NEXT_INC}" "$BUCKET_NAME" "/opt/backup/percona/" "percona-backup"
  echo "Step 3. Cleaning up Percona backup files"
  "$CURRENT_DIR/mysql/percona-clean.sh" "/opt/backup/percona/" "percona-backup"
  
  echo "Done MYSQL INCREMENTAL BACKUP"

fi;

echo "Done with incremental backup"
