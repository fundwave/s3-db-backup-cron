#!/bin/bash

if echo "$MONGODB_URI" | grep -q "MONGODB-AWS"; then
  
  ROLE_NAME=$(curl -s http://169.254.169.254/latest/meta-data/iam/info | awk -F'"' '/\"InstanceProfileArn\"/ { print $4 }' | sed 's:.*/::')
  AWS_CREDENTIALS=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)
  export AWS_ACCESS_KEY_ID=$(echo "$AWS_CREDENTIALS" | awk -F'"' '/\"AccessKeyId\"/ { print $4 }')
  export AWS_SECRET_ACCESS_KEY=$(echo "$AWS_CREDENTIALS" | awk -F'"' '/\"SecretAccessKey\"/ { print $4 }')
  export AWS_SESSION_TOKEN=$(echo "$AWS_CREDENTIALS" | awk -F'"' '/\"Token\"/ { print $4 }')

fi

if [ -z ${MONGO_DATABASES} ]; then
                                                                                                                                         
  CMD_OUT=$(mongodump --uri ${MONGODB_URI} --forceTableScan --out "./mongoBackups/db" 2>&1)                                                
  if (grep -qw "0" <<< $?) then echo "$CMD_OUT"; else echo "$CMD_OUT" 1>&2 ; DUMP_FAILED=true ; fi                                                            

else

  IFS=,                                                                                                                                      
  for val in $MONGO_DATABASES;                                                                                                               
  do                                                                                                                                         
  echo $val                                                                                                                                  
  CMD_OUT=$(mongodump --uri ${MONGODB_URI}/${val} --forceTableScan --out "./mongoBackups/db" 2>&1)                                           
  if (grep -qw "0" <<< $?) then echo "$CMD_OUT"; else echo "$CMD_OUT" 1>&2 ; DUMP_FAILED=true ; fi                                                              
  done                                                                                                                                   

fi

if [ "$DUMP_FAILED" == "true" ]; then
  echo "Error: Failed to backup mongo database." 1>&2
  exit 1
fi
