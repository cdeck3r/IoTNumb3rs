#!/bin/bash

#
# runs the numb3rspipeline.sh script
# for each userdir
# usage: ./run4all.sh <DATAROOT directory>

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

## var test; set default values
if [ -z "$DATAROOT" ]; then
	# set default value
	DATAROOT="/home/iot/testdata"
fi
#
if [ -d "$DATAROOT" ]; then
	# log string
  	TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
  	echo "$TS - $SCRIPT_NAME - INFO - numb3rspipeline's DATAROOT directory configured: $DATAROOT"
else
	# log string
	TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
	echo "$TS - $SCRIPT_NAME - ERROR - numb3rspipeline's DATAROOT directory does not exist: $DATAROOT"
	exit 1
fi
#
if [ -z "$DROPBOX_USERDIR" ]; then
	# set default value
	DROPBOX_USERDIR=( "JinlinHolic" "MariaMarg" "marielledemuth" "Pattoho")
fi
# log string
TS=$(date '+%Y-%m-%d %H:%M:%S,%s')
echo "$TS - $SCRIPT_NAME - INFO - numb3rspipeline's configured for user(s): $DROPBOX_USERDIR"

#
# tools
#
PIPELINE='./numb3rspipeline.sh'
SLACKR='../slackr/slackr'

# call numb3rspipeline for each user
for USERDIR in "${DROPBOX_USERDIR[@]}"
do
	"$PIPELINE" "$DATAROOT"/$USERDIR $USERDIR
	ERR_CODE=$?
    if [ $ERR_CODE -eq 10 ]; then
        "$SLACKR" -r random -n $USERDIR -c warning -i :warning: "numb3rspipeline could not find url_list.txt file for user: $USERDIR"
		continue
	elif [ $ERR_CODE -ne 0 ]; then
		# load slack message file
		# SLACK_MSG_FILE=""$DATAROOT"/"$USERDIR"/slack_msg_errors.txt"
		"$SLACKR" -r random -n $USERDIR -c danger -i :zap: "numb3rspipeline FAILED to process user: $USERDIR"
	else
		# load slack message file
		SLACK_MSG_FILE=""$DATAROOT"/"$USERDIR"/slack_msg_ethercalc.txt"
        echo "numb3rspipeline successfully processed user: $USERDIR" | cat - "$SLACK_MSG_FILE" | "$SLACKR" -r random -n $USERDIR -c good -i :heavy_check_mark:
    fi
done
