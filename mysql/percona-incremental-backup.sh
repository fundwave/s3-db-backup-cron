#!/bin/bash

set -e

MYSQL_USERNAME=${1}
MYSQL_PASSWORD=${2}
SERVER=${3:-'db'}
DATABASE=${4}
FILENAME=${5:-'percona-backup'}
FILE_PATH=${6:-'/opt/backup/percona/'}

# Check if full backup exists
if [ ! -d "${FILE_PATH}full" ]; then
    echo "Error: Full backup not found. Run full backup first." 1>&2
    exit 1
fi

# Create backup directory
mkdir -p "${FILE_PATH}"

# Determine incremental number
LAST_INC=0
if ls "${FILE_PATH}"inc* 1> /dev/null 2>&1; then
    LAST_INC=$(ls -d "${FILE_PATH}"inc* | sed 's/.*inc//' | sort -n | tail -1)
fi
NEXT_INC=$((LAST_INC + 1))

# Determine base directory for incremental
if [ $LAST_INC -eq 0 ]; then
    BASE_DIR="${FILE_PATH}full"
else
    BASE_DIR="${FILE_PATH}inc${LAST_INC}"
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

# Create incremental backup
xtrabackup --backup \
    --defaults-file="$CONFIG_FILE" \
    --target-dir="${FILE_PATH}inc${NEXT_INC}" \
    --incremental-basedir="${BASE_DIR}" \
    --databases="${DATABASE}" || { echo "Error: Failed to create Percona incremental backup." 1>&2; rm -f "$CONFIG_FILE"; exit 1; }

# Remove config file
rm -f "$CONFIG_FILE"

echo "Done creating Percona incremental backup ${NEXT_INC}."
echo "Starting compression..."
tar czf "${FILE_PATH}${FILENAME}-inc${NEXT_INC}.tar.gz" -C "${FILE_PATH}" "inc${NEXT_INC}"
echo "Done compressing the Percona incremental backup file."
