#!/bin/bash        
                                    
FILE=${1:-'backup'}
BUCKET=${2}                                                                                                                                                             
FILE_PATH=$(dirname $FILE_PATH$FILE)                                                                                                                                    
FILE_PATH="${FILE_PATH}""/"                                                                                                                                             
                                                                                                                                                                        
echo "$FILE_PATH""$FILE"                                                                                                                                                
TAR_MD5_SUM=$(openssl md5 -binary "$FILE_PATH$FILE".tar.gz | base64)                                                                                                    
SQL_MD5_SUM=$(openssl md5 -binary $FILE_PATH$FILE".sql" | base64)                                                                                                       
#REMOTE_SQL_MD5_SUM=$(aws s3api head-object --bucket $BUCKET --key "$FILE".tar.gz --query 'Metadata.sqlmd5checksum' --output text)
REMOTE_SQL_MD5_SUM=$(aws s3api head-object --bucket $BUCKET --key "${S3_PREFIX}$FILE".tar.gz --query 'Metadata.sqlmd5checksum' --output text 2>&1) || (if grep -q "An error occurred (404) when calling the HeadObject operation: Not Found" <<< "$REMOTE_SQL_MD5_SUM"; then echo "$REMOTE_SQL_MD5_SUM"; else echo "$REMOTE_SQL_MD5_SUM" 1>&2; fi)

echo $SQL_MD5_SUM                                                                                                                                                       
echo $REMOTE_SQL_MD5_SUM                                                                                                                                                
                                                                                                                                                                        
if [[ "$SQL_MD5_SUM" == "$REMOTE_SQL_MD5_SUM" ]]                                                                                                                        
  then                                                                                                                                                                  
    echo "No changes since last upload. Quitting."                                                                                                                      
    exit 0                                                                                                                                                              
fi                                                                                                                                                                      
                                                                                                                                                                        
echo "Changes found since last upload. Uploading now."                                                                                                                  
                                                                                                                                                                        
aws s3api put-object --bucket $BUCKET --key "${S3_PREFIX:+${S3_PREFIX}/}$FILE".tar.gz --body "$FILE_PATH$FILE".tar.gz --content-md5 $TAR_MD5_SUM --metadata sqlmd5checksum=$SQL_MD5_SUM             
                                                                                                                                                                        
echo "Backup complete"                                                                                                                                                  
