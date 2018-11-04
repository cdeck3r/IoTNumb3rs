#!/bin/bash

#
# Creates a msg file for slack containing Ethercalc page urls
#

#
# Loops through all URL entries of url_filelist.csv
# for each entry
#    creates a new Ethercalc page using CSV_TEMPLATE
#    adds the Ethercalc page URL to each line
# finally, it stores the modifications as new url_filelist.csv
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
