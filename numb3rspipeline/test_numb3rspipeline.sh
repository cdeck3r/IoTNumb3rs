#!/bin/bash

#
# test run of numb3rspipeline

#
# this is a quick hack
# no parameter validation is done
# USE WITH CAUTION
#


# this directory is the script directory
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPT_DIR

# create tmp directory
TESTDIR=/tmp/testdata
mkdir -p "$TESTDIR"
# run the numb3rspipeline for a single (test)user
./run4all.sh "$TESTDIR" testuser
