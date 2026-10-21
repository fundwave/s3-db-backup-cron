#!/bin/bash

SERVER=${SERVER:-"db"}
FILE_NAME=${FILE_NAME:-"backup"}
FILE_PATH=${FILE_PATH:-"/opt/backup/"}
FILE_PATH="${FILE_PATH%/}/"
export FILE_PATH
CURRENT_DIR=$(dirname "$0")

BACKUPS_DISABLED=${BACKUPS_DISABLED:-"false"}

if [ -z ${BUCKET_NAME} ] ; then
  echo "BUCKET_NAME is not set, exiting." 1>&2;
  exit 1;
fi

while [[ "$S3_PREFIX" == /* ]]; do S3_PREFIX="${S3_PREFIX#/}"; done
while [[ "$S3_PREFIX" == */ ]]; do S3_PREFIX="${S3_PREFIX%/}"; done
S3_PREFIX="${S3_PREFIX:+${S3_PREFIX}/}"

if [ -z "${S3_PREFIX}" ] ; then
  echo "S3_PREFIX is not set, backups will be stored in the root of the bucket."
else
  echo "S3_PREFIX is set to ${S3_PREFIX}";
fi
export S3_PREFIX

urlencode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

S3_TAGGING=""
if [ -n "${S3_TAG_KEY}" ] ; then
  S3_TAGGING="$(urlencode "$S3_TAG_KEY")=$(urlencode "$S3_TAG_VALUE")"
  echo "Backups will be tagged with ${S3_TAG_KEY}=${S3_TAG_VALUE}"
elif [ -n "${S3_TAG_VALUE}" ] ; then
  echo "S3_TAG_VALUE is set without S3_TAG_KEY, backups will not be tagged." 1>&2;
fi
export S3_TAGGING

if [ $BACKUPS_DISABLED == 'TRUE' ] || [ $BACKUPS_DISABLED == 'true' ]
then
  echo "No backups since BACKUPS_DISABLED is set to $BACKUPS_DISABLED ."
  exit 0
fi

run_mysql_backup() {
  echo "Step 1. Mysqldump"
  if ! "$CURRENT_DIR/mysql/mysql-backup.sh" "$MYSQL_USERNAME" "$MYSQL_PASSWORD" "$SERVER" "$DB_NAME" "$FILE_NAME" "$FILE_PATH" ; then
    echo "MYSQL dump failed, skipping upload and cleanup." 1>&2;
    return 1
  fi

  echo "Step 2. Saving to S3"
  if ! "$CURRENT_DIR/mysql/backup.sh" "$FILE_NAME" "$BUCKET_NAME" ; then
    echo "MYSQL upload failed, skipping cleanup." 1>&2;
    return 1
  fi

  echo "Step 3. Cleaning it up"
  "$CURRENT_DIR/mysql/clean.sh" "$FILE_NAME"
  return 0
}

run_mongo_backup() {
  echo "Step 1: Mongodump"
  if ! bash "$CURRENT_DIR/mongodb/mongo-backup.sh" ; then
    echo "Mongo dump failed, skipping upload and cleanup." 1>&2;
    return 1
  fi

  echo "Step 2: Saving to S3"
  if ! bash "$CURRENT_DIR/mongodb/s3.sh" ; then
    echo "Mongo upload failed, skipping cleanup." 1>&2;
    return 1
  fi

  echo "Step 3. Cleaning it up"
  bash "$CURRENT_DIR/mongodb/clean.sh"
  return 0
}

if ! [ -z ${DB_NAME} ] && ! [  -z ${SERVER} ] ; then 

  echo "MYSQL BACKUP"
  echo "============"

  if run_mysql_backup ; then
    echo "Done MYSQL"
  else
    BACKUP_FAILED=true
  fi

fi;

if ! [ -z ${MONGODB_URI} ] ; then 

  echo "MONGO BACKUP"
  echo "============"

  if run_mongo_backup ; then
    echo "Done Mongo"
  else
    BACKUP_FAILED=true
  fi

fi;

if [ "$BACKUP_FAILED" == "true" ] ; then
  echo "One or more backups failed." 1>&2;
  exit 1
fi

echo "Done with all backups"
