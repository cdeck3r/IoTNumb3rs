#!/bin/bash

#
# Common funcs of numb3rspipeline
# to be sourced in various scripts
#

# reads and exports all env vars, mostly tokens
export $(egrep -v '^#' $HOME/.env | xargs)

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

# Param #1: path to url_filelist.csv
# Param #2: header of url_filelist.csv
parse_urlfilelist() {
    URL_FILELIST=$1
    URL_FILELIST_HEADER=$2
    # Ex. URL_FILELIST_HEADER="url;filename;home_url;ethercalc_url"
    ERROR=0
    #check url_filelist.csv format
    LINE_CNT=0 # run variable
    while IFS='' read -r URL_STR || [[ -n "$URL_STR" ]]; do
        #
        # some preps
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
            if [ "$URL_STR" == "$URL_FILELIST_HEADER" ]; then
                log_echo "INFO" "File format of url_filelist.csv is OK."
                ERROR=0
            else
                log_echo "ERROR" "Unexpected file format in url_filelist.csv: "$URL_FILELIST""
                RET_PARSE_URLFILELIST+=( "ERROR" )
                ERROR=1
            fi
            # proceed with next line
            continue
        fi

        # processing and error handling
        if [[ $ERROR -ne 0 ]]; then
            break # we stop Processing of url_filelist.csv
        else
            parse_urlstr "$URL_STR"
        fi
    done < "$URL_FILELIST"
}
