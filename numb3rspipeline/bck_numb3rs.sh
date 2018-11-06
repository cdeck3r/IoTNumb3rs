#!/bin/bash

#
# This script stores a copy of the data
# from the numb3rspipeline Ethercalc docs
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

#
# tools
#


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

exit 0

##################################
# 0. prep
# check DATAROOT for git
mkdir -p "$DATAROOT"
cd "$DATAROOT"
git status
if [[ $? -ne 0 ]]; then
    log_echo "WARN" "Data directory is not in git: "$DATAROOT""
    git checkout
    log_echo "INFO" "Checkout"
fi

cd "$SCRIPT_DIR"

# create & goto into DATAPATH
DATAPATH="$DATAROOT"/"$DROPBOX_USERDIR"
mkdir -p "$DATAPATH"
# git init



##################################

# 1.
# Search for user's url_filelist.csv


# 2.
