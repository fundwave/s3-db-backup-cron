#!/bin/bash

set -e

MYSQL_USERNAME=${1}
MYSQL_PASSWORD=${2}
SERVER=${3:-'db'}
DATABASE=${4}
FILENAME=${5:-'percona-backup'}
FILE_PATH=${6:-'/opt/backup/percona/'}

# Create backup directory
mkdir -p ${FILE_PATH}

# Remove previous full backup if exists
if [ -d "${FILE_PATH}full" ]; then
    rm -rf ${FILE_PATH}full
fi

# Create full backup using Percona XtraBackup
xtrabackup --backup \
    --target-dir=${FILE_PATH}full \
    --host=${SERVER} \
    --user=${MYSQL_USERNAME} \
    --password=${MYSQL_PASSWORD} \
    --databases=${DATABASE} || { echo "Error: Failed to create Percona full backup." 1>&2; exit 1; }

# Prepare the backup
xtrabackup --prepare --target-dir=${FILE_PATH}full || { echo "Error: Failed to prepare Percona full backup." 1>&2; exit 1; }

echo "Done creating Percona full backup."
echo "Starting compression..."
tar czf ${FILE_PATH}${FILENAME}-full.tar.gz -C ${FILE_PATH} full
echo "Done compressing the Percona full backup file."
