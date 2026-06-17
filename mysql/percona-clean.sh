#!/bin/bash

FILE_PATH=${1:-'/opt/backup/percona/'}
FILENAME=${2:-'percona-backup'}

echo "Cleaning up Percona backup files..."

# Remove compressed files
rm -f ${FILE_PATH}${FILENAME}-full.tar.gz
rm -f ${FILE_PATH}${FILENAME}-inc*.tar.gz

# Note: We keep the uncompressed directories (full, inc*)
# for incremental backup chain. Only clean them during full backup.

echo "Percona backup cleanup complete."
