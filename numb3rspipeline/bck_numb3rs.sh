#!/bin/bash

#
# This script stores a copy of the data
# from the numb3rspipeline Ethercalc docs
#

# usage
#
# bck_numb3rs.sh <full path local data dir> <dropbox dir name>
#
# Ex.
# bck_numb3rs.sh /home/iot/iotdata_bck testuser
#
#
# exit codes:
# 0 - no error
# 1 - general (fatal) error
# 10 - no compatible url_filelist.csv file not found
# 20 - no new data
#

# this directory is the script directory
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPT_DIR

#
# vars and params
#

# the script's name
SCRIPT_NAME=$0
# this directory stores result of all runs, e.g. /tmp/iotdata
DATAROOT=$1
# the name of the dropbox directory where the url_list is found
DROPBOX_USERDIR=$2

# error record
BCK_ERROR=0

#
# tools
#
GIT='git'
DB_UPLOADER='../Dropbox-Uploader/dropbox_uploader.sh'
CURL='curl'

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
source ./bck_funcs.sh

##################################
# 0. prep
# check and prepare DATAROOT for git

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


# prepare DATAROOT directory
log_echo "INFO" "Prepare backup data directory: "$DATAROOT""
clone_dataroot_git "$DATAROOT"
update_config_dataroot_git "$DATAROOT"
clean_dataroot_git "$DATAROOT"
log_echo "INFO" "All preps done for branch <"$DATA_BRANCH"> in directory: "$DATAROOT""
# back to where you come from
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
# sorted in reverse order
# => youngest file is on first pos
SORTED_FILELIST=($(echo "${ALL_URL_FILELIST[@]}" | sort -r))
#echo "${SORTED_FILELIST[@]}"
for LIST_ELEMENT in "${SORTED_FILELIST[@]}"
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
        # only set if previously
        ### FIXME: BCK_ERROR&=BCK_ERROR
        if [[ $BCK_ERROR -ne 0 ]]; then
            BCK_ERROR=10
        fi
        # next file
        continue
    fi

    # # backup each ethercalc documents in various formats
    for EC_URL in "${RET_PARSE_URLFILELIST[@]}"
    do
        log_echo "INFO" "Download ethercalc "$EC_URL""
        "$CURL" -s -S -L -k -O "$EC_URL.csv" # > "$DATAPATH"/$(basename "$EC_URL.csv")
        "$CURL" -s -S -L -k -O "$EC_URL.xlxs" # > "$DATAPATH"/$(basename "$EC_URL.csv")
        "$CURL" -s -S -L -k -O "$EC_URL.md"  # > "$DATAPATH"/$(basename "$EC_URL.csv")
    done
    # clear DATAPATH dir from url_filelist.csv
    rm -rf "$DATAPATH"/url_filelist.csv
    BCK_ERROR=0
done

# clear DATAPATH dir from leftovers
rm -rf "$DATAPATH"/url_filelist.csv

# 3.
# transfer the backup files into the branch <iotdata> the github repo
#
# update README.md
update_readme_dataroot_git "$DATAROOT" "$DROPBOX_USERDIR"
# commit and push files
commit_push_dataroot_git "$DATAROOT" "$DROPBOX_USERDIR"

# return to where you come from
cd "$SCRIPT_DIR"
# done done
exit $BCK_ERROR
