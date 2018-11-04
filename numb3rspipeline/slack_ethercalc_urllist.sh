#!/bin/bash

#
# Creates a msg file for slack containing Ethercalc page urls
#

#
# Loops through all URL entries of url_filelist.csv
# for each entry
#   add Ethercalc page URL into message file
#
# Input: url_filelist.csv
# Output: slack msg file in the directory of url_filelist.csv
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
URL_FILELIST=$1

# for testing only
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

# parse url_filelist.csv
# loop through all lines of $URL_FILELIST
# for each entry
#   extract Ethercalc page URL
#
log_echo "INFO" "Reading url_filelist: "$URL_FILELIST""
# stores slack msg file in the directory of url_filelist.csv
SLACK_MSG_FILE=$(dirname "$URL_FILELIST")/slack_msg_ethercalc.txt
# message
SLACK_MSG="Ethercalc URLs:"
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

    # create the message
    SLACK_MSG=""$SLACK_MSG"\n"$ethercalc_url""

done < "$URL_FILELIST"

# Store slack msg file
# do not forget -e to let the echo behave correctly on \n
log_echo "INFO" "Write slack msg file: $SLACK_MSG_FILE"
echo -e "$SLACK_MSG" > "$SLACK_MSG_FILE"

# testing
#USERDIR=testuser
#echo "numb3rspipeline successfully processed user: $USERDIR" | cat - "$SLACK_MSG_FILE" | ../slackr/slackr -r DC2S098MC -n $USERDIR -c good -i :heavy_check_mark:
