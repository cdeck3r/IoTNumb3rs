#!/bin/bash

#
# Initailly creates the Ethercalc document
#

#
# Example
#
# echo 'one,two,three' | \
#    curl -i -H "Content-Type: text/csv" -X POST --data-binary @- \
#        https://ethercalc.org/_/test-74
#

# we need something like a default .csv template

#
# Command line params
#
# Quick hack; No parameter validation
# USE WITH CAUTION
#
SCRIPT_NAME=$0
CSV_TEMPLATE=$1
URL_FILELIST=$2
