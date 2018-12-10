#!/bin/bash

#
# runs the bck_cleanup.sh script
# for each userdir
# usage: ./bck_cleanup_allusers.sh <DATAROOT directory>

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

# report file
DQ_REPORT=""$DATAROOT"/dq.md"

# include common funcs
source ./funcs.sh

log_echo "INFO" "Create numb3rs data quality report."

## var test; set default values
if [ -z "$DATAROOT" ]; then
	# set default value
	DATAROOT=""$HOME"/iotdata_bck"
fi
#
if [ -d "$DATAROOT" ]; then
	# log string
  	log_echo "INFO" "numb3rs DATAROOT directory configured: $DATAROOT"
else
	# log string
	log_echo "ERROR" "numb3rs DATAROOT directory does not exist: $DATAROOT"
	exit 1
fi
#
if [ -z "$DROPBOX_USERDIR" ]; then
	# set default value
	DROPBOX_USERDIR=( "JinlinHolic" "MariaMarg" "marielledemuth" "Pattoho" )
fi
# log string
log_echo "INFO" "numb3rs data quality report configured for user(s): "${DROPBOX_USERDIR[@]}""

#
# tools
#
DQNUMB3RS='./dq_numb3rs.sh'
SLACKR='../slackr/slackr'

# Prepare user list to use it as script parameter later on
for USERDIR in "${DROPBOX_USERDIR[@]}"
do
	ALLUSERS="$ALLUSERS "$USERDIR""
done

# call data quality report for each user
INITDQ=1
for USERDIR in "${DROPBOX_USERDIR[@]}"
do
	"$DQNUMB3RS" "$DATAROOT" "$USERDIR" $INITDQ "${ALLUSERS[@]}"
	ERR_CODE=$?
	if [[ $INITDQ -ne 0 ]]; then
		INITDQ=0
	fi
	if [ $ERR_CODE -eq 20 ]; then
		"$SLACKR" -r random -n $USERDIR -c good -i :white_check_mark: "Nothing has changed for user: $USERDIR"
		continue
	elif [ $ERR_CODE -ne 0 ]; then
		# load slack message file
		# SLACK_MSG_FILE=""$DATAROOT"/"$USERDIR"/slack_msg_errors.txt"
		"$SLACKR" -r random -n $USERDIR -c danger -i :heavy_exclamation_mark: "Data quality report FAILED for user: $USERDIR"
	else
		# load slack message file
		SLACK_MSG_FILE="/tmp/slack_msg_dq.txt"
        echo "Successfully created data quality report for user: $USERDIR" | cat - "$SLACK_MSG_FILE" | "$SLACKR" -r random -n $USERDIR -c good -i :bar_chart:
		#"$SLACKR" -r random -n $USERDIR -c good -i :heavy_check_mark: "Successfully created data quality report for user: $USERDIR"
    fi
done
