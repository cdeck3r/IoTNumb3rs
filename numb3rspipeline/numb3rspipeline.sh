#!/bin/bash

#
# this is a quick hack
# no parameter validation is done
# USE WITH CAUTION
#

# usage
#
# numb3rspipeline.sh <full path local data dir> <dropbox dir name>
#
# Ex.
# numb3rspipeline.sh /home/iot/testdata testuser
#
# exit codes:
# 0 - no error
# 1 - general errors
# 10 - url_list.txt file not found
#

# this directory is the script directory
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPT_DIR

#
# vars and params
#

# the script's name
SCRIPT_NAME=$0
# this directory stores result of all runs
DATAROOT=$1
# the name of the dropbox directory where the url_list is found
DROPBOX_USERDIR=$2

# each pipeline run stores its results in this directory
DATADIR=$(date '+%Y%m%d-%H%M')

#
# tools
#
DB_UPLOADER='../Dropbox-Uploader/dropbox_uploader.sh'
TESSERACT='./tesseract.py'
IMG_DOWNLOAD='./img_download.sh'
SETUP_ETHERCALC='./setup_ethercalc.sh'
FILL_ETHERCALC='./fill_ethercalc.sh'

# datapath
DATAPATH="$DATAROOT"/"$DATADIR"
mkdir -p "$DATAPATH"

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

# log string
log_echo "INFO" "Run numb3rspipeline for $DROPBOX_USERDIR"

# 0.
# [name of url_list] = dropbox list [userdir]
#
# log string
log_echo "INFO" "Detect url_list.txt filename for $DROPBOX_USERDIR"

# dropbox list [userdir]
#"$DB_UPLOADER" list "$DROPBOX_USERDIR"
mapfile -t DIRLIST < <( "$DB_UPLOADER" list "$DROPBOX_USERDIR" )
# loop through each element of list
for LIST_ELEMENT in "${DIRLIST[@]}"
do
    # empty var
    URL_LIST_NAME=
    URL_LIST_NAME=$(echo "${LIST_ELEMENT}" | egrep -o '([[:space:][:alpha:]]+ - )?url_list.txt$' | sed -e 's/^[[:space:]]*//')
    if [ -n "$URL_LIST_NAME" ]; then
        break
    fi
done

# report about the result
if [ -n "$URL_LIST_NAME" ]; then
    # log string
    log_echo "INFO" "url_list.txt filename for $DROPBOX_USERDIR: $URL_LIST_NAME"
else
    # log string
    log_echo "ERROR" "url_list.txt filename for $DROPBOX_USERDIR not found."
    exit 10
fi


# 1.
# url_list = dropbox download [userdir]
#
# log string and download file
log_echo "INFO" "Download url_list.txt from $DROPBOX_USERDIR"
"$DB_UPLOADER" download /"$DROPBOX_USERDIR"/"$URL_LIST_NAME" "$DATAPATH"/url_list.txt
# error reporting
if [[ $? -ne 0 ]]; then
    log_echo "ERROR" "Error downloading url_list.txt from $DROPBOX_USERDIR"
    exit 1
fi

# MOCK
#echo 'https://iot.telefonica.com/sites/default/files/2017_iot_trends_eng_960_2.png' \
#    >> "$DATAROOT"/"$DATADIR"/url_list.txt
#echo 'https://iot.telefonica.com/sites/default/files/2017_iot_trends_eng_960_2.png' \
#    >> "$DATAROOT"/"$DATADIR"/url_list.txt
#touch "$DATAROOT"/"$DATADIR"/url_list.txt

# 2.
# [url_filelist] = img_dwnload [yyyymmdd-HHMM, url_list]
#
"$IMG_DOWNLOAD" "$DATAPATH" "$DATAPATH"/url_list.txt

# 3.
# tesseract [-u url_filelist] [yyyymmdd-HHMM]
python "$TESSERACT" "$DATAPATH"

# 4.
# setup_ethercalc [template, url_filelist.csv]
"$SETUP_ETHERCALC" "$SCRIPT_DIR"/numb3rs_template.csv "$DATAPATH"/url_filelist.csv
if [[ $? -ne 0 ]]; then
    # record the result for slack
    log_echo "ERROR" "Fatal error when setup Ethercalc for $DROPBOX_USERDIR. Abort."
    exit 1
fi

# 5.
# fill_ethercalc [template, url_filelist.csv]
"$FILL_ETHERCALC" "$SCRIPT_DIR"/numb3rs_template.csv "$DATAPATH"/url_filelist.csv
if [[ $? -ne 0 ]]; then
    # record the result for slack
    log_echo "ERROR" "Fatal error when fill Ethercalc for $DROPBOX_USERDIR. Abort."
    exit 1
fi

# 6.
# dropbox upload [yyyymmdd-HHMM]
# dropbox delete [url_list.txt]
# logging
log_echo "INFO" "Upload $DATAPATH to $DROPBOX_USERDIR"
# dropload upload
"$DB_UPLOADER" upload "$DATAPATH" /"$DROPBOX_USERDIR"
if [[ $? -ne 0 ]]; then
    log_echo "ERROR" "Error uploading $DATAPATH to $DROPBOX_USERDIR. Abort."
    exit 1
fi
# logging
log_echo "INFO" "Delete /"$DROPBOX_USERDIR"/url_list.txt"
"$DB_UPLOADER" delete /"$DROPBOX_USERDIR"/"$URL_LIST_NAME"
