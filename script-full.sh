#!/bin/bash

SERVER=${SERVER:-"db"}
FILE_NAME=${FILE_NAME:-"backup"}
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

  echo "MYSQL FULL BACKUP"
  echo "================="

  # Regular mysqldump backup
  echo "Step 1. Mysqldump"
  "$CURRENT_DIR/mysql/mysql-backup.sh" "$MYSQL_USERNAME" "$MYSQL_PASSWORD" "$SERVER" "$DB_NAME" "$FILE_NAME" "$FILE_PATH"
  echo "Step 2. Saving mysqldump to S3"
  "$CURRENT_DIR/mysql/backup.sh" "$FILE_NAME" "$BUCKET_NAME"
  echo "Step 3. Cleaning up mysqldump files"
  "$CURRENT_DIR/mysql/clean.sh" "$FILE_NAME"

  # Percona full backup
  echo "Step 4. Percona Full Backup"
  "$CURRENT_DIR/mysql/percona-full-backup.sh" "$MYSQL_USERNAME" "$MYSQL_PASSWORD" "$SERVER" "$DB_NAME" "percona-backup" "/opt/backup/percona/"
  echo "Step 5. Saving Percona full backup to S3"
  "$CURRENT_DIR/mysql/percona-s3-upload.sh" "full" "$BUCKET_NAME" "/opt/backup/percona/" "percona-backup"
  echo "Step 6. Cleaning up Percona backup files"
  "$CURRENT_DIR/mysql/percona-clean.sh" "/opt/backup/percona/" "percona-backup"
  
  echo "Done MYSQL FULL BACKUP"

fi;

if ! [ -z ${MONGODB_URI} ] ; then 

  echo "MONGO BACKUP"
  echo "============"

  echo "Step 1: Mongodump"
  bash "$CURRENT_DIR/mongodb/mongo-backup.sh"
  echo "Step 2: Saving to S3"
  bash "$CURRENT_DIR/mongodb/s3.sh"
  echo "Step 3. Cleaning it up"
  bash "$CURRENT_DIR/mongodb/clean.sh"
  echo "Done Mongo"

fi;


echo "Done with all full backups"
