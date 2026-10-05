#!/bin/bash

FILE=${1:-'backup'}
BUCKET=${2}
FILE_PATH=$(dirname $FILE_PATH$FILE)
FILE_PATH="${FILE_PATH}""/"

echo "$FILE_PATH""$FILE"
TAR_MD5_SUM=$(openssl md5 -binary "$FILE_PATH$FILE".tar.gz | base64)
SQL_MD5_SUM=$(openssl md5 -binary $FILE_PATH$FILE".sql" | base64)
#REMOTE_SQL_MD5_SUM=$(aws s3api head-object --bucket $BUCKET --key "$FILE".tar.gz --query 'Metadata.sqlmd5checksum' --output text)
REMOTE_STATE=$(aws s3api head-object --bucket $BUCKET --key "${S3_PREFIX}$FILE".tar.gz --query "join('|', [Metadata.sqlmd5checksum || '', Metadata.s3tagging || ''])" --output text 2>&1) || (if grep -q "An error occurred (404) when calling the HeadObject operation: Not Found" <<< "$REMOTE_STATE"; then echo "$REMOTE_STATE"; else echo "$REMOTE_STATE" 1>&2; fi)

LOCAL_STATE="$SQL_MD5_SUM|$S3_TAGGING"

echo $LOCAL_STATE
echo $REMOTE_STATE

if [[ "$LOCAL_STATE" == "$REMOTE_STATE" ]]
  then
    echo "No changes since last upload. Quitting."
    exit 0
fi

echo "Changes found since last upload. Uploading now."

METADATA="{\"sqlmd5checksum\":\"$SQL_MD5_SUM\"${S3_TAGGING:+,\"s3tagging\":\"$S3_TAGGING\"}}"

aws s3api put-object --bucket $BUCKET --key "${S3_PREFIX}$FILE".tar.gz --body "$FILE_PATH$FILE".tar.gz --content-md5 $TAR_MD5_SUM --metadata "$METADATA" ${S3_TAGGING:+--tagging "$S3_TAGGING"} || { echo "Upload failed" 1>&2; exit 1; }

echo "Backup complete"
