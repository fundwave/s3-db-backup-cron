#!/bin/bash
#echo "Env Variables:" $MYSQL_USERNAME $MYSQL_PASSWORD $SERVER $DB_NAME $FILE_NAME $FILE_PATH
echo "Restoring backup using bucket"
# $BUCKET_NAME
DB_SERVER=${SERVER:-'db'}
FILENAME=${FILE_NAME:-'backup'}
FILE_PATH=${FILE_PATH:-'/opt/backup'}
VERSION_ID=$1
AWS_ARGS=$2
echo "Taking local backup before restoration... "
sh mysql-backup.sh $MYSQL_USERNAME $MYSQL_PASSWORD $DB_SERVER $DB_NAME $FILE_NAME $FILE_PATH

timestamp() {
  date  +"%Y-%m-%d_%H-%M-%S" # current time
}

TIME_STAMP=$(timestamp)
#TIME_STAMP="2022-02-16_17-28-07"
BACKUP_FILE="restore-$TIME_STAMP"

echo "Getting last backup..."
if [[ -z "$VERSION_ID" || "$VERSION_ID" == 'latest' ]]; then VERSION_OPTION=''; else VERSION_OPTION="--version-id $VERSION_ID"; fi
aws s3api get-object --bucket $BUCKET_NAME --key "${S3_PREFIX}$FILENAME".tar.gz $BACKUP_FILE.tar.gz $VERSION_OPTION $AWS_ARGS

echo "Extracting last backup..."
mkdir -p "$FILE_PATH"restores
tar -xvzf $BACKUP_FILE.tar.gz --directory "$FILE_PATH"restores
mv "$FILE_PATH"restores/backup.sql "$FILE_PATH"restores/backup.sql.${TIME_STAMP}

echo "Restoring from last backup to database $DB_NAME ..."
mysql -h ${SERVER} --user=${MYSQL_USERNAME} --password=${MYSQL_PASSWORD} ${DB_NAME} < ${FILE_PATH}restores/backup.sql.${TIME_STAMP}

echo "Done"
