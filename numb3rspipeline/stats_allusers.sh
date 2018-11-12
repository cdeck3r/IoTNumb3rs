#!/bin/bash

#
# runs the stats_numb3rs.sh script
# for each userdir
# usage: ./stats_allusers.sh <DATAROOT directory> user

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
  	log_echo "INFO" "numb3rs statistics DATAROOT directory configured: $DATAROOT"
else
	# log string
	log_echo "ERROR" "numb3rs statistics DATAROOT directory does not exist: $DATAROOT"
	exit 1
fi
#
if [ -z "$DROPBOX_USERDIR" ]; then
	# set default value
	DROPBOX_USERDIR=( "JinlinHolic" "MariaMarg" "marielledemuth" "Pattoho" "ManualUser")
fi
# log string
log_echo "INFO" "numb3rs statistics configured for user(s): "${DROPBOX_USERDIR[@]}""

#
# tools
#
STATSNUMB3RS='./stats_numb3rs.sh'
SLACKR='../slackr/slackr'

# call numb3rspipeline for each user
for USERDIR in "${DROPBOX_USERDIR[@]}"
do
	"$STATSNUMB3RS" "$DATAROOT" $USERDIR
	ERR_CODE=$?
	if [ $ERR_CODE -ne 0 ]; then
		# load slack message file
		# SLACK_MSG_FILE=""$DATAROOT"/"$USERDIR"/slack_msg_errors.txt"
		"$SLACKR" -r random -n $USERDIR -c danger -i :heavy_exclamation_mark: "Statistics computation FAILED for user: $USERDIR"
	else
		"$SLACKR" -r random -n $USERDIR -c good -i :1234: "Successful statistics computation for user: $USERDIR"
    fi
done
