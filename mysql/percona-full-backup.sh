#!/bin/bash

set -e

MYSQL_USERNAME=${1}
MYSQL_PASSWORD=${2}
SERVER=${3:-'db'}
DATABASE=${4}
FILENAME=${5:-'percona-backup'}
FILE_PATH=${6:-'/opt/backup/percona/'}

# Create backup directory
mkdir -p "${FILE_PATH}"

# Remove previous full backup if exists
if [ -d "${FILE_PATH}full" ]; then
    rm -rf "${FILE_PATH}full"
fi

# Create MySQL config file for secure password passing
CONFIG_FILE="/tmp/xtrabackup.cnf"
cat > "$CONFIG_FILE" << EOF
[client]
user=${MYSQL_USERNAME}
password=${MYSQL_PASSWORD}
host=${SERVER}
EOF
chmod 600 "$CONFIG_FILE"

# Create full backup using Percona XtraBackup
xtrabackup --backup \
    --defaults-file="$CONFIG_FILE" \
    --target-dir="${FILE_PATH}full" \
    --databases="${DATABASE}" || { echo "Error: Failed to create Percona full backup." 1>&2; rm -f "$CONFIG_FILE"; exit 1; }

# Prepare the backup
xtrabackup --prepare --target-dir="${FILE_PATH}full" || { echo "Error: Failed to prepare Percona full backup." 1>&2; rm -f "$CONFIG_FILE"; exit 1; }

# Remove config file
rm -f "$CONFIG_FILE"

echo "Done creating Percona full backup."
echo "Starting compression..."
tar czf "${FILE_PATH}${FILENAME}-full.tar.gz" -C "${FILE_PATH}" full
echo "Done compressing the Percona full backup file."
