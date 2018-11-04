#!/bin/bash

#
# Fills a previously created Ethercalc document
#

#
# Loops through all URL entries of url_filelist.csv
# for each entry
#    extracts the Ethercalc page URL
#    adds data to the Ethercalc page URL
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
#CSV_TEMPLATE="${SCRIPT_DIR}/numb3rs_template.csv"
#URL_FILELIST="${SCRIPT_DIR}/../testdata/testuser/url_filelist.csv"

DATA_LINE=
EC_URL=
# loop through all lines of $URL_FILELIST
# for each entry
#    extracts the Ethercalc page URL
#    adds data to the Ethercalc page URL
#
log_echo "INFO" "Reading url_filelist: "$URL_FILELIST""
LINE_CNT=0 # run variable
while IFS='' read -r URL_STR || [[ -n "$URL_STR" ]]; do

    #
    # some preps
    #
    # removes newline
    URL_STR=$(echo "$URL_STR" | tr -d '\n' | tr -d '\r')
    # test if URL_STR is empty (= fake lines)
    if [[ -z "$URL_STR" ]]; then
        continue
    fi
    # 1st true line of url_filelist is just the header
    # restart loop
    LINE_CNT=$((LINE_CNT + 1))
    if [ $LINE_CNT -eq 1 ]; then
        # file format check
        URL_FILELIST_HEADER="url;filename;home_url;ethercalc_url"
        if [ "$URL_STR" == "$URL_FILELIST_HEADER" ]; then
            log_echo "INFO" "File format of url_filelist.csv is OK."
        else
            log_echo "ERROR" "Unexpected file format in url_filelist.csv: "$URL_FILELIST""
            exit 1
        fi
        # proceed with next line
        continue
    fi

    #
    # extract data form url_filelist.csv
    #
    url=$(echo "$URL_STR" | cut -d ';' -f1)
    filename=$(echo "$URL_STR" | cut -d ';' -f2)
    home_url=$(echo "$URL_STR" | cut -d ';' -f3)
    ethercalc_url=$(echo "$URL_STR" | cut -d ';' -f4)

    # Extract dropbox dir
    DROPBOX_DIR=$(echo $(dirname "$URL_FILELIST") | rev | cut -d '/' -f1-2 | rev)

    # compile data to add
    DATA_LINE=""$url","$home_url","$filename",,,,,,,,"$DROPBOX_DIR""
    log_echo "INFO" "Add new data to "$ethercalc_url": "$DATA_LINE""

    # Ethercalc overwrite Command
    # template + data overwrites *completely* the existing data
    EC_URL="$(dirname "$ethercalc_url")/_/$(basename "$ethercalc_url")"
    read -r -d '' CURL_EC_OVERWRITE << EOM
echo "$DATA_LINE" | cat "$CSV_TEMPLATE" -| \
curl --include \
     --request PUT \
     --header "Content-Type: text/csv" \
     --data-binary @- '$EC_URL'
EOM
    #echo "$CURL_EC_OVERWRITE"

    # run Ethercalc cmd to overwrite the page's content
    CURL_RET="$(eval "$CURL_EC_OVERWRITE")"
    if [[ $? -ne 0 ]]; then
        log_echo "ERROR" "Error running cURL cmd: "$CURL_EC_OVERWRITE""
        continue
    fi

    # parse returned data
    # test string issuing a state transition
    CURL_OK=0
    CURL_OK_STR="HTTP/1.1 201 Created"
    while IFS='' read -r CURL_RET_STR || [[ -n "$CURL_RET_STR" ]]; do

        # removes newline
        CURL_RET_STR=$(echo "$CURL_RET_STR" | tr -d '\n' | tr -d '\r')

        # simple state machine
        # CURL_OK=0 -> CURL_OK=1 ->
        if [ "$CURL_OK" -eq 0 ] && [ "$CURL_RET_STR" == "$CURL_OK_STR" ]; then
            CURL_OK=1
            log_echo "INFO" "Data successfully added to Ethercalc: $ethercalc_url"
        fi
    done <<< "$CURL_RET"
    # if CURL_OK is finally still 0, then raise ERROR
    if [ "$CURL_OK" -eq 0 ]; then
        log_echo "ERROR" "Could not add content to Ethercalc: $ethercalc_url"
    fi

done < "$URL_FILELIST"
