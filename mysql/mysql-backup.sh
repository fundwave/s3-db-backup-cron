#!/bin/bash

set -e

MYSQL_USERNAME=${1}
MYSQL_PASSWORD=${2}
SERVER=${3:-'db'}
DATABASE=${4}
FILENAME=${5:-'backup'}
FILE_PATH=${6:-'/opt/backup'}
EXCLUDE_TABLES=${7:-''}

# Build the mysqldump command with ignore-table options
IGNORE_TABLE_ARGS=""
if [ -n "$EXCLUDE_TABLES" ]; then
  IFS=',' read -ra TABLES <<< "$EXCLUDE_TABLES"
  for TABLE in "${TABLES[@]}"; do
    # Trim whitespace
    TABLE=$(echo "$TABLE" | xargs)
    if [ -n "$TABLE" ]; then
      IGNORE_TABLE_ARGS="${IGNORE_TABLE_ARGS} --ignore-table=${DATABASE}.${TABLE}"
    fi
  done
fi

mysqldump -h ${SERVER} --skip-dump-date --quick --user=${MYSQL_USERNAME} --password=${MYSQL_PASSWORD} ${IGNORE_TABLE_ARGS} ${DATABASE} > ${FILE_PATH}${FILENAME}.sql || { echo "Error: Failed to backup mysql database." 1>&2; }

echo "Done backing up the database to a file."
echo "Starting compression..."
tar czf ${FILE_PATH}${FILENAME}.tar.gz ${FILE_PATH}${FILENAME}.sql
echo "Done compressing the backup file."
