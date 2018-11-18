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

echo "============ [Test] numb3rspipeline - Fixture Setup ============"
echo "Setup ... "
# create tmp directory
TESTDIR=/tmp/testdata
TESTUSER=testuser
rm -rf "$TESTDIR"
mkdir -p "$TESTDIR"
echo "Done."
echo "============ [Test] numb3rspipeline - Run ============"
echo "Dir: "$TESTDIR""
echo "User: "$TESTUSER""
# run the numb3rspipeline for a single (test)user
./run4all.sh "$TESTDIR" "$TESTUSER"

# test file existence
echo "============ [Test] numb3rspipeline - File Test Run ============"
TESTFILES=( "url_list.txt" "url_filelist.csv" )
for TF in "${TESTFILES[@]}"
do
    CURR_TESTFILE=$(ls "$TESTDIR"/testuser/*/"$TF")
    if [ ! -f "$CURR_TESTFILE" ]; then
        echo "Test ERROR - :-("
        echo "File does not exist: "$CURR_TESTFILE""
        exit 1
    fi
done
echo "File Test OK - :-)"


# check
echo "============ [Test] numb3rspipeline - Content Test Run ============"

URL_CNT=$(cat "$TESTDIR"/testuser/*/url_list.txt | sed '/^\s*$/d' | wc -l)
URL_CNT=$((URL_CNT + 1)) # add 1 to count last line
FILE_CNT=$(ls -l "$TESTDIR"/testuser/*/file*_*.txt | wc -l)

if [[ $URL_CNT -ne $FILE_CNT ]]; then
    echo "Test ERROR - :-("
    echo "URLs in url_list.csv: $URL_CNT"
    echo "Processed files: $FILE_CNT"
else
    echo "Content Test OK - :-)"
fi

### TODO delete Ethercalc pages
echo "============ [Test] numb3rspipeline - Tear Down ============"

read -r -d '' CURL_EC_OVERWRITE << EOM
curl --include --request PUT '$ethercalc_url'
EOM

URL_FILELIST=$(tail +2 "$TESTDIR"/testuser/*/url_filelist.csv)
while IFS='' read -r URL_STR || [[ -n "$URL_STR" ]]; do
    # removes newline
    URL_STR=$(echo "$URL_STR" | tr -d '\n' | tr -d '\r')
    # test if URL_STR is empty
    if [[ -z "$URL_STR" ]]; then
        continue
    fi

    ethercalc_url=$(echo $URL_STR | cut -d ';' -f4)
    # run Ethercalc cmd to overwrite the page's content
    echo "Clear Ethercalc page "$ethercalc_url""
    # Ethercalc overwrite Command
    # template + data overwrites *completely* the existing data
    EC_URL="$(dirname "$ethercalc_url")/_/$(basename "$ethercalc_url")"
    read -r -d '' CURL_EC_OVERWRITE << EOM
echo "," |  \
curl --include \
     --request PUT \
     --header "Content-Type: text/csv" \
     --data-binary @- '$EC_URL'
EOM
    # run Ethercalc cmd to overwrite the page's content
    CURL_RET="$(eval "$CURL_EC_OVERWRITE")"
    if [[ $? -ne 0 ]]; then
        echo "Error when clearing Ethercalc page "$ethercalc_url""
        continue
    fi
done <<< "$URL_FILELIST"
echo "Done."
