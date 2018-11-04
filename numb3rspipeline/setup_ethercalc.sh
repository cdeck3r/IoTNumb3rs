#!/bin/bash

#
# Initailly creates the Ethercalc document
#

#
# Example
#
# echo 'one,two,three' | \
#    curl -i -H "Content-Type: text/csv" -X POST --data-binary @- \
#        https://ethercalc.org/_/test-74
#

# this directory is the script directory
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPT_DIR

#
# Command line params
#
# Quick hack; No parameter validation
# USE WITH CAUTION
#
SCRIPT_NAME=$0
CSV_TEMPLATE=$1
URL_FILELIST=$2

#
# logging on stdout
# Param #1: log level, e.g. INFO, WARN, ERROR
# Param #2: log message
log_echo () {
    LOG_LEVEL=$1
    LOG_MSG=$2
    TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
    echo "$TS - $SCRIPT_NAME - $LOG_LEVEL - $LOG_MSG"
}

# for testing only
CSV_TEMPLATE="${SCRIPT_DIR}/numb3rs_template.csv"
URL_FILELIST="${SCRIPT_DIR}/../testdata/testuser/url_filelist.csv"


# HTTP/1.1 201 Created
# Location: xxx

read -r -d '' CURL_EC_CREATE << EOM
curl --include \
     --request POST \
     --header "Content-Type: text/csv" \
     --data-binary @numb3rs_template.csv 'https://www.ethercalc.org/_'
EOM

#echo $CURL_EC_CREATE

# create ethercalc document
#CURL_RET="$(eval "$CURL_EC_CREATE")"

# mockup return info from CURL call
read -r -d '' CURL_RET << EOM
HTTP/1.1 201 Created
Server: nginx/1.13.8
Date: Sat, 03 Nov 2018 19:59:09 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 13
Connection: keep-alive
X-Powered-By: Zappa 0.5.0
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: X-Requested-With,Content-Type,If-Modified-Since
Access-Control-Allow-Methods: GET,POST,PUT
Location: /_/g76iwlq96nvo
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
EOM

#echo RETURN: "$CURL_RET"

# possible return
# HTTP/1.1 201 Created
# Server: nginx/1.13.8
# Date: Sat, 03 Nov 2018 19:59:09 GMT
# Content-Type: text/plain; charset=utf-8
# Content-Length: 13
# Connection: keep-alive
# X-Powered-By: Zappa 0.5.0
# Access-Control-Allow-Origin: *
# Access-Control-Allow-Headers: X-Requested-With,Content-Type,If-Modified-Since
# Access-Control-Allow-Methods: GET,POST,PUT
# Location: /_/g76iwlq96nvo
# Strict-Transport-Security: max-age=31536000; includeSubDomains; preload


# loop through all lines returned from $EC_CREATE
EC_LOCATION=
EC_URL=
CURL_OK_STR="HTTP/1.1 201 Created"
CURL_LOCATION_SUBSTR="Location:"
CURL_OK=0
CURL_LOCATION_FOUND=0
while IFS='' read -r CURL_RET_STR || [[ -n "$CURL_RET_STR" ]]; do

    # simple state machine
    # CURL_OK=0 -> CURL_OK=1 ->
    # -> CURL_LOCATION_FOUND=0 -> CURL_LOCATION_FOUND=1
    if [ "$CURL_OK" -eq 0 ] && [ "$CURL_RET_STR" == "$CURL_OK_STR" ]; then
        CURL_OK=1
    fi

    if [ "$CURL_OK" -eq 1 ] &&  [[ "$CURL_RET_STR" == *"$CURL_LOCATION_SUBSTR"* ]]; then
        CURL_LOCATION_FOUND=1
        EC_LOCATION=$(echo "$CURL_RET_STR" | cut -d ' ' -f2)
    fi
done <<< "$CURL_RET"

# EC_LOCATION contains the doc path to the newly created Ethercalc page
# if not, something went wrong and we print out the CURL return data
if [[ ! -z "$EC_LOCATION" ]]; then
    # create final URL
    EC_URL="https://www.ethercalc.org/"$(echo "$EC_LOCATION" | cut -d '/' -f3)
    # log string
    log_echo "INFO" "Sucessfully created Ethercalc page at: $EC_URL"
else
    log_echo "ERROR" "Could not create Ethercalc page."
    echo "$CURL_RET"
fi

exit 0
# Modify the url_filelist.csv



exit 0

read -r -d '' CURL_EC_OVERWRITE << EOM
curl --include \
     --request PUT \
     --header "Content-Type: text/csv" 'https://www.ethercalc.org/_/id'
EOM
