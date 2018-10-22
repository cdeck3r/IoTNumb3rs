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

# datapath
DATAPATH="$DATAROOT"/"$DATADIR"
mkdir -p "$DATAPATH"

# log string
TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
echo "$TS - $SCRIPT_NAME - INFO - Run numb3rspipeline for $DROPBOX_USERDIR"

# 0.
# [name of url_list] = dropbox list [userdir]
#
# log string
TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
echo "$TS - $SCRIPT_NAME - INFO - Detect url_list.txt filename for $DROPBOX_USERDIR"

# dropbox list [userdir]
#"$DB_UPLOADER" list "$DROPBOX_USERDIR"
mapfile -t DIRLIST < <( "$DB_UPLOADER" list "$DROPBOX_USERDIR" )
# loop through each element of list
for LIST_ELEMENT in "${DIRLIST[@]}"
do
    # empty var
    URL_LIST_NAME=
    URL_LIST_NAME=$(echo "${LIST_ELEMENT}" | egrep -o '([[:space:][:alpha:]]+ - )?url_list.txt$' | awk '{$1=$1}1')
    if [ -n "$URL_LIST_NAME" ]; then
        break
    fi
done

# report about the result
if [ -n "$URL_LIST_NAME" ]; then
    # log string
    TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
    echo "$TS - $SCRIPT_NAME - INFO - url_list.txt filename for $DROPBOX_USERDIR: $URL_LIST_NAME"
else
    # log string
    TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
    echo "$TS - $SCRIPT_NAME - ERROR - url_list.txt filename for $DROPBOX_USERDIR not found."
    exit 10
fi


# 1.
# url_list = dropbox download [userdir]
#
# log string and download file
TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
echo "$TS - $SCRIPT_NAME - INFO - Download url_list.txt from $DROPBOX_USERDIR"
"$DB_UPLOADER" download /"$DROPBOX_USERDIR"/"$URL_LIST_NAME" "$DATAPATH"/url_list.txt
# error reporting
if [[ $? -ne 0 ]]; then
    TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
    echo "$TS - $SCRIPT_NAME - ERROR - Error downloading url_list.txt from $DROPBOX_USERDIR"
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
# dropbox upload [yyyymmdd-HHMM]
# dropbox delete [url_list.txt]
# logging
TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
echo "$TS - $SCRIPT_NAME - INFO - Upload $DATAPATH to $DROPBOX_USERDIR"
# dropload upload
"$DB_UPLOADER" upload "$DATAPATH" /"$DROPBOX_USERDIR"
if [[ $? -ne 0 ]]; then
    TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
    echo "$TS - $SCRIPT_NAME - ERROR - Error uploading $DATAPATH to $DROPBOX_USERDIR"
    exit 1
fi
# logging
TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
echo "$TS - $SCRIPT_NAME - INFO - Delete /"$DROPBOX_USERDIR"/url_list.txt"
"$DB_UPLOADER" delete /"$DROPBOX_USERDIR"/"$URL_LIST_NAME"
