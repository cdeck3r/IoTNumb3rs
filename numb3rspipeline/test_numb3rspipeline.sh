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
rm -rf "$TESTDIR"
mkdir -p "$TESTDIR"
# run the numb3rspipeline for a single (test)user
./run4all.sh "$TESTDIR" testuser

# test file existence
TESTFILES=( "url_list.txt" "url_filelist.csv" )
for TF in "${TESTFILES[@]}"
do
    if [ ! -f "$TESTDIR/testuser/*/$TF" ]; then
        echo "Test ERROR - :-("
        echo "File does not exist: "$TESTFILES/testuser/*/$TF""
        exit 1
    fi
done
echo "File Test OK - :-)"


# check
URL_CNT=$(cat "$TESTDIR/testuser/*/url_list.txt" | wc -l)
FILE_CNT=$(ls -l "$TESTDIR/testuser/*/file_*.txt" | wc -l)

if [[ $URL_CNT -ne $FILE_CNT ]]; then
    echo "Test ERROR - :-("
    echo "URLs in url_list.csv: $URL_CNT"
    echo "Processed files: $FILE_CNT"
fi
echo "Content Test OK - :-)"

### TODO delete Ethercalc pages
