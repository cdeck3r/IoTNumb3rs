#!/bin/bash

#
# This script stores a copy of the data
# from the numb3rspipeline Ethercalc docs
#


# this directory is the script directory
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPT_DIR

# specific parsing func
# called by ./funcs.sh/parse_urlfilelist()
#
# Param #1: data line from url_filelist.csv
RET_PARSE_URLFILELIST=()
parse_urlstr() {
    URL_STR=$1
    if [ -n "$URL_STR" ]; then
        ethercalc_url=$(echo "$URL_STR" | cut -d ';' -f4)
        RET_PARSE_URLFILELIST+=( "$ethercalc_url" )
    fi
}

# include common funcs
source ./funcs.sh


#
# vars and params
#

# the script's name
SCRIPT_NAME=$0
# this directory stores result of all runs, e.g. /tmp/iotdata
DATAROOT=$1
# the name of the dropbox directory where the url_list is found
DROPBOX_USERDIR=$2

# for testing only
DATAROOT=/tmp/iotdata
DROPBOX_USERDIR=testuser

#
# tools
#
GIT='git'
DB_UPLOADER='../Dropbox-Uploader/dropbox_uploader.sh'



##################################
# 0. prep
# check DATAROOT for git

########
# Create an orphan branch "iotdata"
# cd /tmp
# git clone https://github.com/cdeck3r/IoTNumb3rs.git iotdata
# cd iotdata/
# git checkout --orphan iotdata
# git rm -rf .
# echo "# IoTNumb3rs Data Backup" > README.md
# git add *
# git config user.name "Christian Decker"
# git config user.email "cdecker@outlook.de"
# git commit -m "Initial commit with README.md"
# git push --set-upstream origin iotdata
########

mkdir -p "$DATAROOT"
cd "$DATAROOT"
$GIT status
if [[ $? -eq 128 ]]; then
    log_echo "WARN" "Data directory is not in git: "$DATAROOT""
    log_echo "INFO" "Clone branch <iotdata> in "$DATAROOT""
    # one dir up, e.g. /tmp
    cd "$(dirname "$DATAROOT")"
    # ... and clone branch iodata into ./iotdata
    $GIT clone https://github.com/cdeck3r/IoTNumb3rs.git \
    --branch iotdata \
    --single-branch \
    $(basename "$DATAROOT")
    if [[ $? -ne 0 ]]; then
        log_echo "ERROR" "GIT does not work. Abort."
        exit 1
    fi
fi

# Update DATAROOT directory
cd "$DATAROOT"
log_echo "INFO" "Switch directory to branch <iotdata> and pull into: "$DATAROOT""
$GIT branch --set-upstream-to origin/iotdata iotdata
$GIT reset --hard # throw away all uncommited changes
$GIT checkout iotdata
$GIT pull origin iotdata

GIT_STATUS="$(git status --branch --short)"
log_echo "INFO" "Branch <iotdata> status is: "$GIT_STATUS""

# set remote url containing token var
# each time git is used, the var should be replaced by its current value
$GIT remote set-url --push origin https://${GITHUB_OAUTH_ACCESS_TOKEN}@github.com/cdeck3r/IoTNumb3rs.git
$GIT config user.name "Christian Decker"
$GIT config user.email "cdecker@outlook.de"

log_echo "INFO" "All preps done for branch <iotdata> in directory: "$DATAROOT""

cd "$SCRIPT_DIR"

# prep done.

##################################

# create & goto into DATAPATH (= user specific dir)
DATAPATH="$DATAROOT"/"$DROPBOX_USERDIR"
mkdir -p "$DATAPATH"
cd "$DATAPATH"
log_echo "INFO" "Processing user data directory: "$DATAPATH""

##################################

# 1.
# Search for user's url_filelist.csv
mapfile -t FILELIST < <( "$SCRIPT_DIR/$DB_UPLOADER" search url_filelist.csv )

# loop through each element of list
ALL_URL_FILELIST=()
for LIST_ELEMENT in "${FILELIST[@]}"
do
    URL_FILELIST=
    URL_FILELIST=$(echo "${LIST_ELEMENT}" | egrep -o "/$DROPBOX_USERDIR"'/[[:digit:]]{8}-[[:digit:]]{4}/url_filelist.csv$' )

    if [ -n "$URL_FILELIST" ]; then
        ALL_URL_FILELIST+=( "$URL_FILELIST" )
    fi
done
#echo "${ALL_URL_FILELIST[@]}"
# 2.
# loop through the Ethercalc URLs of each url_filelist.csv
# ...
SORTED_FILELIST=()
SORTED_FILELIST="$(echo "${ALL_URL_FILELIST[@]}" | sort)"
#echo "${SORTED_FILELIST[@]}"
for LIST_ELEMENT in "${ALL_URL_FILELIST[@]}"
do
    URL_FILELIST="$LIST_ELEMENT"

    # download from dropbox
    log_echo "INFO" "Download from dropbox "$URL_FILELIST""
    rm -rf "$DATAPATH"/url_filelist.csv
    "$SCRIPT_DIR/$DB_UPLOADER" download "$URL_FILELIST" ""$DATAPATH"/url_filelist.csv"

    # parse url_filelist.csv
    RET_PARSE_URLFILELIST=()
    #URL_FILELIST_HEADER="url;filename;home_url;ethercalc_url"
    parse_urlfilelist "${DATAPATH}/url_filelist.csv" "url;filename;home_url;ethercalc_url"
    if [ "${RET_PARSE_URLFILELIST[0]}" == "ERROR" ]; then
        # next file
        continue
    fi

    # # backup each ethercalc documents in various formats
    for EC_URL in "${RET_PARSE_URLFILELIST[@]}"
    do
        curl -L -k -J -On "$EC_URL.csv"
        curl -L -k -J -On "$EC_URL.xlxs"
        curl -L -k -J -On "$EC_URL.md"
    done
    # clear DATAPATH dir from url_filelist.csv
    rm -rf "$DATAPATH"/url_filelist.csv
done

# clear DATAPATH dir from leftovers
rm -rf "$DATAPATH"/url_filelist.csv

# push using github token
echo " " >> "$DATAROOT"/README.md
echo "Date: $(date '+%Y-%m-%d %H:%M:%S,%s');" \
    "User: $DROPBOX_USERDIR;" \
    "Files: $(ls -l $DATAPATH | wc -l )" >> "$DATAROOT"/README.md
cd "$DATAROOT"
$GIT add *
$GIT commit -m "Testing push using github personal access token"
$GIT push
# revert to original URL in order to avoid token to be stored
$GIT remote set-url --push origin "https://github.com/cdeck3r/IoTNumb3rs.git"
