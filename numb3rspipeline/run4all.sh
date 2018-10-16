#!/bin/bash

#
# runs the numb3rspipeline.sh script
# for each userdir
#

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
DATAROOT="/home/iot/testdata"
DROPBOX_USERDIR=( "JinlinHolic" "MariaMarg" "marielledemuth" "Pattoho")

#
# tools
#
PIPELINE='./numb3rspipeline.sh'
SLACKR='../slackr/slackr'

# call numb3rspipeline for each user
for USERDIR in "${DROPBOX_USERDIR[@]}"
do
	"$PIPELINE" "$DATAROOT"/$USERDIR $USERDIR
    if [[ $? -ne 0 ]]; then
        "$SLACKR" -r random -n $USERDIR -c danger -i :zap: "numb3rspipeline FAILED to process user: $USERDIR"
    else
        "$SLACKR" -r random -n $USERDIR -c good -i :heavy_check_mark: "numb3rspipeline successfully processed user: $USERDIR"
    fi
done
