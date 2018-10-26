#!/bin/bash

#
# Downloads URL content using curl
#

#
# Command line params
#
# Quick hack; No parameter validation
# USE WITH CAUTION
#
SCRIPT_NAME=$0
DOWNLOAD_DIR=$1
URL_LIST=$2

# all file ops within download directory
cd "$DOWNLOAD_DIR"
# output file
URL_FILELIST='./url_filelist.csv'

# initially create the URL_FILELIST
echo "url"\;"filename"\;"home_url" > "$URL_FILELIST"

FILE_CNT=0
# loop through all lines of $URL_LIST
# 1. Download $URL
# 2. rename downloaded files by prefixing $FILE_CNT
while IFS='' read -r URL_STR || [[ -n "$URL_STR" ]]; do

    #### parse url_list.txt file
    URL=$(echo $URL_STR | cut -d ';' -f 1)
    HOME_URL=$(echo $URL_STR | cut -d ';' -f 2)

    # compatibility with preious format, when no home_url is provided
    if [ "$HOME_URL" == "$URL" ]; then
        HOME_URL=
    fi

    #### time snapshot using aux file 'start' before download
    start_date=$(date '+%Y%m%d%H%M.%S')
    touch -t ${start_date} start

    # log string and download file
    TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
    echo "$TS - $SCRIPT_NAME - INFO - Download $URL"
    # removes \CR at the end
    URL=${URL%$'\r'}
    URL=$(echo "$URL" | egrep -o '^[[:alnum:]:/._-]+')
    # download
    curl -L -k -J -On "$URL"

    #### find file created during download and rename
    FILE_CNT=$((FILE_CNT + 1))
    (
    export FILE_CNT
    find "." -type f -name '*.*' ! -name '*.csv' ! -name '*.txt' \
        -newer start \
        -exec sh -c 'mv "{}" file"$FILE_CNT"_"$(basename "{}")"' \;
    )

    # write the url_filelist
    (
    export URL
    export HOME_URL
    export FILE_CNT
    export URL_FILELIST
    find "." -type f -name '*.*' ! -name '*.csv' ! -name '*.txt' \
        -newer start \
        -exec sh -c 'echo "$URL"\;"$(basename "{}")"\;"$HOME_URL" >> "$URL_FILELIST"' \;
    )
    # remove aux 'start' file
    rm -rf ./start
    # needed to make find work in the next round
    sleep 10s

done < "$URL_LIST"
