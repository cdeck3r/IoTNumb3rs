#!/bin/bash

#
# Initially creates the Ethercalc document
#

#
# Loops through all URL entries of url_filelist.csv
# for each entry
#    creates a new Ethercalc page using CSV_TEMPLATE
#    adds the Ethercalc page URL to each line
# finally, it stores the modifications as new url_filelist.csv
#
# Input: csv template, url_filelist.csv
# Output: url_filelist.csv with links to default Ethercalc pages (default=template)
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

# for testing only
CSV_TEMPLATE="${SCRIPT_DIR}/numb3rs_template.csv"
URL_FILELIST="${SCRIPT_DIR}/../testdata/testuser/url_filelist.csv"

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

# CURL POST request to create an Ethercalc page
# using the template
read -r -d '' CURL_EC_CREATE << EOM
curl --include \
     --request POST \
     --header "Content-Type: text/csv" \
     --data-binary @${CSV_TEMPLATE} 'https://www.ethercalc.org/_'
EOM

#echo $CURL_EC_CREATE

#
# Example of CURL_RET return data
#
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

# loop through all lines of $URL_FILELIST
# 1. at 1st line add header field
# 2. for each other URL_STR create a new ethercalc page and add EC_URL
#
# Finally, after the loop, stores the content of the modified url_filelist.csv
NEW_URL_FILELIST=
LINE_CNT=0 # run variable
while IFS='' read -r URL_STR || [[ -n "$URL_STR" ]]; do

    # removes newline
    URL_STR=$(echo "$URL_STR" | tr -d '\n' | tr -d '\r')
    # test if URL_STR is empty
    if [[ -z "$URL_STR" ]]; then
        continue
    fi

    LINE_CNT=$((LINE_CNT + 1))
    # add header af the end of first line in url_filelist
    # restart loop
    if [ $LINE_CNT -eq 1 ]; then
        NEW_URL_FILELIST=""$URL_STR";ethercalc_url"
        continue
    fi

    # create new Ethercalc page
    CURL_RET="$(eval "$CURL_EC_CREATE")"

    # parse the result in CURL_RET

    # loop through all lines returned from $CURL_RET
    # variables to be set in state machine
    EC_LOCATION=
    EC_URL=
    # state machine states
    CURL_OK=0
    CURL_LOCATION_FOUND=0
    # test strings issuing a state transition
    CURL_OK_STR="HTTP/1.1 201 Created"
    CURL_LOCATION_SUBSTR="Location:"
    while IFS='' read -r CURL_RET_STR || [[ -n "$CURL_RET_STR" ]]; do

        # removes newline
        CURL_RET_STR=$(echo "$CURL_RET_STR" | tr -d '\n' | tr -d '\r')

        # simple state machine
        # CURL_OK=0 -> CURL_OK=1 ->
        # CURL_LOCATION_FOUND=0 -> CURL_LOCATION_FOUND=1
        # -> result: found location where new ethercalc page is stored
        if [ "$CURL_OK" -eq 0 ] && [ "$CURL_RET_STR" == "$CURL_OK_STR" ]; then
            CURL_OK=1
        fi

        if [ "$CURL_OK" -eq 1 ] &&  [[ "$CURL_RET_STR" == *"$CURL_LOCATION_SUBSTR"* ]]; then
            CURL_LOCATION_FOUND=1
            EC_LOCATION=$(echo "$CURL_RET_STR" | cut -d ' ' -f2)
        fi

    done <<< "$CURL_RET"

    # EC_LOCATION now contains the doc path to the newly created Ethercalc page
    # So, we can create the final ethercalc doc URL: EC_URL
    # if something went wrong, we'll print out the CURL return data and proceed
    if [[ ! -z "$EC_LOCATION" ]]; then
        # create final URL
        EC_URL="https://www.ethercalc.org/"$(echo "$EC_LOCATION" | cut -d '/' -f3)
        # log string
        log_echo "INFO" "Sucessfully created Ethercalc page at: $EC_URL"
    else
        # EC_URL stays empty, too
        log_echo "ERROR" "Could not create Ethercalc page."
        echo "$CURL_RET"
    fi

    # modify the url_filelist.csv
    # add the new EC_URL
    NEW_URL_FILELIST=""$NEW_URL_FILELIST"\n"$URL_STR";"$EC_URL""

done < "$URL_FILELIST"

# Store NEW_URL_FILELIST as url_filelist.csv
# do not forget -e to let the echo behave correctly on \n
echo -e "$NEW_URL_FILELIST" > "$URL_FILELIST"
log_echo "INFO" "Updated url_filelist.csv: $URL_FILELIST"

exit 0

read -r -d '' CURL_EC_OVERWRITE << EOM
echo "one, two, three" ",,five" | cat "$CSV_TEMPLATE" -| \
curl --include \
     --request PUT \
     --header "Content-Type: text/csv" \
     --data-binary @- 'https://www.ethercalc.org/_/id'
EOM
