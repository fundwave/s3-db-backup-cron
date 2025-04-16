#!/bin/bash

SERVER=${SERVER:-"db"}
FILE_NAME=${FILE_NAME:-"backup"}
CURRENT_DIR=$(dirname $0)

BACKUPS_DISABLED=${BACKUPS_DISABLED:-"false"}

if [ $BACKUPS_DISABLED == 'TRUE' ] || [ $BACKUPS_DISABLED == 'true' ]
then
  echo "No backups since BACKUPS_DISABLED is set to $BACKUPS_DISABLED ."
  exit 0
fi

mkdir -p /var/log/backup.log

if ! [ -z ${DB_NAME} ] && ! [  -z ${SERVER} ] ; then 

  echo "MYSQL BACKUP"
  echo "============"

  echo "Step 1. Mysqldump"
  $CURRENT_DIR/mysql/mysql-backup.sh $MYSQL_USERNAME $MYSQL_PASSWORD $SERVER $DB_NAME $FILE_NAME $FILE_PATH >> /var/log/backup.log 2>&1
  echo "Step 2. Saving to S3"
  $CURRENT_DIR/mysql/backup.sh $FILE_NAME $BUCKET_NAME >> /var/log/backup.log 2>&1
  echo "Step 3. Cleaning it up"
  $CURRENT_DIR/mysql/clean.sh $FILE_NAME >> /var/log/backup.log 2>&1
  echo "Done MYSQL"

fi;

if ! [ -z ${MONGODB_URI} ] ; then 

  echo "MONGO BACKUP"
  echo "============"

  echo "Step 1: Mongodump"
  bash $CURRENT_DIR/mongodb/mongo-backup.sh >> /var/log/backup.log 2>&1
  echo "Step 2: Saving to S3"
  bash $CURRENT_DIR/mongodb/s3.sh >> /var/log/backup.log 2>&1
  echo "Step 3. Cleaning it up"
  bash $CURRENT_DIR/mongodb/clean.sh >> /var/log/backup.log 2>&1
  echo "Done Mongo"

fi;


echo "Done with all backups"
