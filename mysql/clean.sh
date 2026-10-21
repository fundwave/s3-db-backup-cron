#!/bin/bash

FILENAME=${1:-'backup'}
TMP_PATH=${FILE_PATH:-'/opt/backup/'}

echo "Removing the cache files..."
# remove databases dump

echo ${TMP_PATH}${FILENAME}
rm ${TMP_PATH}${FILENAME}.sql
rm ${TMP_PATH}${FILENAME}.tar.gz

