#!/bin/bash

#
# identifies failed downloads and re-downloads them
#

# usage
#
# bck_cleanup.sh <full path local data dir> <dropbox dir name>
#
# Ex.
# bck_cleanup.sh /home/iot/iotdata_bck testuser
#
#
# exit codes:
# 0 - no error
# 1 - general (fatal) error
# 20 - no new data


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
# template for ethercalc format
NUMB3RS_TEMPLATE="$SCRIPT_DIR"/numb3rs_template.csv
NUMB3RS_TEMPLATE_FILESIZE=$(stat -c %s "$NUMB3RS_TEMPLATE")
# error record
BCK_ERROR=0

#
# tools
#
GIT='git'
CURL='curl'

# include common funcs
source ./funcs.sh
source ./bck_funcs.sh

# prepare DATAROOT directory
log_echo "INFO" "Prepare backup data directory: "$DATAROOT""
clone_dataroot_git "$DATAROOT"
update_config_dataroot_git "$DATAROOT"
clean_dataroot_git "$DATAROOT"
log_echo "INFO" "All preps done for branch <iotdata> in directory: "$DATAROOT""
# back to where you come from
cd "$SCRIPT_DIR"

##################################

# create & goto into DATAPATH (= user specific dir)
DATAPATH="$DATAROOT"/"$DROPBOX_USERDIR"
mkdir -p "$DATAPATH"
cd "$DATAPATH"
log_echo "INFO" "Processing user data directory: "$DATAPATH""

##################################

# loop through all csv files of DROPBOX_USERDIR containing '<html>' string
for CSVFILE in $(find "$DATAPATH" -type f -name '*.csv' | xargs grep -l '<html>' 2> /dev/null)
do
    # grep for expected header
    # either    "IoTNumb3rs Datenerfassung"
    # or        "URL,filename"
    head -1 "$CSVFILE" | grep "IoTNumb3rs Datenerfassung\|URL,filename" > /dev/null
    if [[ $? -ne 0 ]]; then
        log_echo "WARN" "File not valid: $CSVFILE"
        # constructs ethercalc URL from filename and download
        EC_URL=$(basename "$CSVFILE" | cut -d '.' -f 1)
        EC_URL="https://www.ethercalc.org/"${EC_URL}
        log_echo "INFO" "Download ethercalc "$EC_URL""
        "$CURL" -s -S -L -k -O "$EC_URL.csv" # > "$DATAPATH"/$(basename "$EC_URL.csv")
        "$CURL" -s -S -L -k -O "$EC_URL.xlxs" # > "$DATAPATH"/$(basename "$EC_URL.csv")
        "$CURL" -s -S -L -k -O "$EC_URL.md"  # > "$DATAPATH"/$(basename "$EC_URL.csv")
    else
        log_echo "INFO" "File format ok: $CSVFILE"
    fi
done
log_echo "INFO" "All files processed for user: "$DROPBOX_USERDIR""

# update README.md
update_readme_dataroot_git "$DATAROOT" "$DROPBOX_USERDIR"
# commit and push files
commit_push_dataroot_git "$DATAROOT" "$DROPBOX_USERDIR"

# return to where you come from
cd "$SCRIPT_DIR"

# done done
exit $BCK_ERROR
