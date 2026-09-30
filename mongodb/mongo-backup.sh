#!/bin/bash

if echo "$MONGODB_URI" | grep -q "MONGODB-AWS"; then
  
  ROLE_NAME=$(curl -s http://169.254.169.254/latest/meta-data/iam/info | awk -F'"' '/\"InstanceProfileArn\"/ { print $4 }' | sed 's:.*/::')
  AWS_CREDENTIALS=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)
  export AWS_ACCESS_KEY_ID=$(echo "$AWS_CREDENTIALS" | awk -F'"' '/\"AccessKeyId\"/ { print $4 }')
  export AWS_SECRET_ACCESS_KEY=$(echo "$AWS_CREDENTIALS" | awk -F'"' '/\"SecretAccessKey\"/ { print $4 }')
  export AWS_SESSION_TOKEN=$(echo "$AWS_CREDENTIALS" | awk -F'"' '/\"Token\"/ { print $4 }')

fi

MONGO_FILTERS=${MONGO_FILTERS:-"{}"}
if ! jq -e 'type == "object" and all(.[]; .collection | type == "string")' <<< "$MONGO_FILTERS" > /dev/null; then
  echo "MONGO_FILTERS must be a JSON object mapping each database to {\"collection\": ..., \"query\": ...}" 1>&2
  exit 1
fi

uri_for_db() {
  local URI=$1 DB=$2 OPTIONS=""
  if [[ "$URI" == *\?* ]]; then
    OPTIONS="?${URI#*\?}"
    URI=${URI%%\?*}
  fi
  local SCHEME=${URI%%://*}
  local HOSTS=${URI#*://}
  HOSTS=${HOSTS%%/*}
  echo "$SCHEME://$HOSTS/$DB$OPTIONS"
}

filter_args() {
  local DB=$1
  FILTER_ARGS=(--forceTableScan)
  local COLLECTION=$(jq -r --arg db "$DB" '.[$db].collection // empty' <<< "$MONGO_FILTERS")
  [ -z "$COLLECTION" ] && return
  FILTER_ARGS+=(--collection "$COLLECTION")
  local QUERY=$(jq -c --arg db "$DB" '.[$db].query // empty' <<< "$MONGO_FILTERS")
  [ -n "$QUERY" ] && FILTER_ARGS=(--collection "$COLLECTION" --query "$QUERY")
}

if [ -z ${MONGO_DATABASES} ]; then
                                                                                                                                         
  CMD_OUT=$(mongodump --uri ${MONGODB_URI} --forceTableScan --out "./mongoBackups/db" 2>&1)                                                
  if (grep -qw "0" <<< $?) then echo "$CMD_OUT"; else echo "$CMD_OUT" 1>&2 ; fi                                                            

else

  IFS=,                                                                                                                                      
  for val in $MONGO_DATABASES;                                                                                                               
  do                                                                                                                                         
  echo $val                                                                                                                                  
  filter_args "$val"
  CMD_OUT=$(mongodump --uri "$(uri_for_db "$MONGODB_URI" "$val")" "${FILTER_ARGS[@]}" --out "./mongoBackups/db" 2>&1)                                           
  if (grep -qw "0" <<< $?) then echo "$CMD_OUT"; else echo "$CMD_OUT" 1>&2 ; fi                                                              
  done                                                                                                                                   

fi