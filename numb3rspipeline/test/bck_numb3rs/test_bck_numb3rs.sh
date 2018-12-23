#!/bin/bash

#
# test unit of numb3rspipeline
#
# Prepare Dropbox
# 1. clean up dropbox testuser
# 2. create testuser dir on dropbox
# 3. upload testdata to dropbox
#
# Prepare github
# 1. create iotdata-test branch
# 1. clone iotdata-test branch
#
# run test
# compare output with oracle
#
# tear down
#

# reads and exports all env vars, mostly tokens
export $(egrep -v '^#' $HOME/.env | xargs)

# this directory is the script directory
#SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
SCRIPT_DIR="$( pwd -P )"

#
# vars and params
#
# the script's name
SCRIPT_NAME=$0
# this directory stores result of all runs, e.g. /tmp/iotdata
DATAROOT=$1
# the name of the dropbox directory where the url_list is found
DROPBOX_USERDIR=$2
# other vars
ORACLE_FILE="$SCRIPT_DIR/bck_numb3rs.oracle"
TEST_LOG_FILE="$SCRIPT_DIR/bck_numb3rs.log"
TESTDATA="$SCRIPT_DIR/testdata"
PIPELINE="$SCRIPT_DIR/../.."
TEST_UNIT="$PIPELINE/bck_numb3rs.sh"
DATA_BRANCH="iotdata"
DATA_BRANCH_TEST="iotdata-test"
# testing
DATAROOT="/tmp/$DATA_BRANCH_TEST"
DROPBOX_USERDIR="testuser"
#
DATAPATH="$DATAROOT"/"$DROPBOX_USERDIR"


# tools
#
GIT='git'
DIFF='diff'
DB_UPLOADER="$PIPELINE/../Dropbox-Uploader/dropbox_uploader.sh"

##
# Here starts the pre-prep and post-prep of unit test
##

# 1. clean up dropbox testuser
# 2. create testuser dir on dropbox
# 3. upload testdata to dropbox

setup_local() {
    rm -rf "$DATAROOT"
    mkdir -p "$DATAROOT"
}

setup_git() {
    # delete iotdata-test branch
    # copy iotdata branch nach iotdata-test
    cd $DATAROOT
    $GIT clone https://github.com/cdeck3r/IoTNumb3rs.git \
        -b "$DATA_BRANCH" --single-branch "$DATAROOT" && \
    $GIT checkout -b "$DATA_BRANCH_TEST" "$DATA_BRANCH" && \
    $GIT remote set-url \
        --push origin https://${GITHUB_OAUTH_ACCESS_TOKEN}@github.com/cdeck3r/IoTNumb3rs.git && \
    $GIT config user.name "Christian Decker" && \
    $GIT config user.email "christian.decker@reutlingen-university.de" && \
    $GIT push --set-upstream origin "$DATA_BRANCH_TEST"
    $GIT branch --set-upstream-to origin/$DATA_BRANCH_TEST $DATA_BRANCH_TEST

    # empty download directory
    rm -rf "$DATAPATH"/*
    git rm "$DATAPATH"/*
    git commit -m "Cleanup directory for testing user: "$DROPBOX_USERDIR""
    $GIT push
}

setup_dropbox() {
    echo "Upload test data into dropbox for user: "$DROPBOX_USERDIR""
    "$DB_UPLOADER" delete "/$DROPBOX_USERDIR"
    "$DB_UPLOADER" upload "$TESTDATA" "/$DROPBOX_USERDIR"
}

# will run first, when unit test starts
setup() {
    # test for TEST_LOG_FILE
    if [ ! -f "$TEST_LOG_FILE" ]; then
        echo "Run TEST_UNIT: "$TEST_UNIT""
        # run TEST_UNIT
        "$TEST_UNIT" "$DATAROOT" "$DROPBOX_USERDIR" > "$TEST_LOG_FILE"
    else
        echo "TEST_UNIT did run previously: "$TEST_UNIT""
    fi
}

# will run once before any unit test starts
setup_suite() {
    echo "setup_suite()"
    rm -rf "$TEST_LOG_FILE"
    setup_dropbox && \
    setup_local && setup_git
}

# will run once after all unit test are completed
teardown_suite() {
    echo "teardown_suite()"
    cd "$DATAROOT"
    #$GIT checkout "$DATA_BRANCH" && \
    # the TEST_UNIT may reset the config
    $GIT remote set-url \
        --push origin https://${GITHUB_OAUTH_ACCESS_TOKEN}@github.com/cdeck3r/IoTNumb3rs.git && \
    $GIT config user.name "Christian Decker" && \
    $GIT config user.email "christian.decker@reutlingen-university.de" && \
    $GIT push --set-upstream origin "$DATA_BRANCH_TEST"
    # delete remote branch
    $GIT push origin --delete "$DATA_BRANCH_TEST"
    #$GIT branch --delete --force "$DATA_BRANCH_TEST" && \
    echo ""
    echo "############################################"
    echo ""
    echo "Files are left for additional manual checks."
    echo "Logfile: "$TEST_LOG_FILE""
    echo "Data files: $DATAPATH"
    echo ""
    echo "############################################"
}

##
# Here are the unit tests
##
test_INFO_diff_check() {
    assert "diff <(grep -e '- INFO -' "$TEST_LOG_FILE" | cut -d' ' -f 8- ) \
            <(grep -e '- INFO -' "$ORACLE_FILE" | cut -d' ' -f 8-)"
    assert true
}

test_WARN_diff_check() {
    assert "diff <(grep -e '- WARN -' "$TEST_LOG_FILE" | cut -d' ' -f 8- ) \
            <(grep -e '- WARN -' "$ORACLE_FILE" | cut -d' ' -f 8-)"
    assert true
}

test_ERROR_diff_check() {
    assert "diff <(grep -e '- ERROR -' "$TEST_LOG_FILE" | cut -d' ' -f 8- ) \
            <(grep -e '- ERROR -' "$ORACLE_FILE" | cut -d' ' -f 8-)"
    assert true
}

#
# File count check test for
# the number of downloaded files
#
aux_EC_URL_COUNT() {
    local EC_URL_COUNT
    local EC_DATA_HEADER="URL,filename,home_url,ethercalc_url"
    EC_URL_COUNT=$(csvstack -d ';' -K 1 -H "$TESTDATA"/*/url_filelist.csv \
                | tail -n +2 | sed -e '1i\' -e "$EC_DATA_HEADER" \
                | csvcut -c 4 | grep -v  '^\"\"' | tail -n +2 | wc -l)
    echo $EC_URL_COUNT
}

test_csv_filecount_check() {
    CSV_FILE_COUNT=$(ls -l "$DATAPATH"/*.csv | wc -l)
    EC_URL_COUNT=$(aux_EC_URL_COUNT)
    # 3 dups and 1 errornous URL
    EC_URL_COUNT=$((EC_URL_COUNT-4))
    assert "test $CSV_FILE_COUNT -eq $EC_URL_COUNT"
}

test_md_filecount_check() {
    MD_FILE_COUNT=$(ls -l "$DATAPATH"/*.md | wc -l)
    EC_URL_COUNT=$(aux_EC_URL_COUNT)
    # 3 dups and 1 errornous URL
    EC_URL_COUNT=$((EC_URL_COUNT-4))
    assert "test $MD_FILE_COUNT -eq $EC_URL_COUNT"
}

test_xlxs_filecount_check() {
    XLXS_FILE_COUNT=$(ls -l "$DATAPATH"/*.xlxs | wc -l)
    EC_URL_COUNT=$(aux_EC_URL_COUNT)
    # 3 dups and 1 errornous URL
    EC_URL_COUNT=$((EC_URL_COUNT-4))
    assert "test $XLXS_FILE_COUNT -eq $EC_URL_COUNT"
}

test_ec_download_url_count_check() {
    EC_URL_COUNT=$(aux_EC_URL_COUNT)
    EC_DOWNLOAD_URL_COUNT=$(grep "Download ethercalc" "$TEST_LOG_FILE" | wc -l)
    assert "test $EC_URL_COUNT -eq $EC_DOWNLOAD_URL_COUNT"
}
