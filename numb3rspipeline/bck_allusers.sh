#!/bin/bash

#
# runs the bck_numb3rs.sh script
# for each userdir
# usage: ./bck_allusers.sh <DATAROOT directory>

#
# this is a quick hack
# no parameter validation is done
# USE WITH CAUTION
#


# this directory is the script directory
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPT_DIR

#
# vars and params
#
SCRIPT_NAME=$0
DATAROOT=
DATAROOT=$1
DROPBOX_USERDIR=
DROPBOX_USERDIR=$2

# include common funcs
source ./funcs.sh

## var test; set default values
if [ -z "$DATAROOT" ]; then
	# set default value
	DATAROOT=""$HOME"/iotdata_bck"
fi
#
if [ -d "$DATAROOT" ]; then
	# log string
  	log_echo "INFO" "numb3rs backup DATAROOT directory configured: $DATAROOT"
else
	# log string
	log_echo "ERROR" "numb3rs backup DATAROOT directory does not exist: $DATAROOT"
	exit 1
fi
#
if [ -z "$DROPBOX_USERDIR" ]; then
	# set default value
	DROPBOX_USERDIR=( "JinlinHolic" "MariaMarg" "marielledemuth" "Pattoho")
fi
# log string
log_echo "INFO" "numb3rs backup configured for user(s): "${DROPBOX_USERDIR[@]}""

#
# tools
#
BCKNUMB3RS='./bck_numb3rs.sh'
SLACKR='../slackr/slackr'

# call numb3rspipeline for each user
for USERDIR in "${DROPBOX_USERDIR[@]}"
do
	"$BCKNUMB3RS" "$DATAROOT" $USERDIR
	ERR_CODE=$?
	if [ $ERR_CODE -eq 20 ]; then
        "$SLACKR" -r random -n $USERDIR -c good -i :do_not_litter: "No new data to backup for user: $USERDIR"
		continue
	elif [ $ERR_CODE -eq 10 ]; then
        "$SLACKR" -r random -n $USERDIR -c warning -i :warning: "Data backup could not find a valid url_filelist.csv for user: $USERDIR"
		continue
	elif [ $ERR_CODE -ne 0 ]; then
		# load slack message file
		# SLACK_MSG_FILE=""$DATAROOT"/"$USERDIR"/slack_msg_errors.txt"
		"$SLACKR" -r random -n $USERDIR -c danger -i :heavy_exclamation_mark: "Data backup FAILED for user: $USERDIR"
	else
		"$SLACKR" -r random -n $USERDIR -c good -i :floppy_disc: "Data backup successfully run for user: $USERDIR"
    fi
done
