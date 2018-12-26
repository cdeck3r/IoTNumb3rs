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
ORACLE_FILE="$SCRIPT_DIR/bck_cleanup.oracle"
TEST_LOG_FILE="$SCRIPT_DIR/bck_cleanup.log"
TESTDATA="$SCRIPT_DIR/testdata"
PIPELINE="$SCRIPT_DIR/../.."
TEST_UNIT="$PIPELINE/bck_cleanup.sh"
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

setup_testdata() {
    echo "Upload test data into <$DATA_BRANCH_TEST> branch for user: "$DROPBOX_USERDIR""
    cd $DATAROOT
    mkdir -p "$DATAPATH"
    cp "$TESTDATA"/* "$DATAPATH"
    git add *
    git commit -m "Test data for testing user: "$DROPBOX_USERDIR""
    $GIT push
}

# will run first, when unit test starts
setup() {
    # test for TEST_LOG_FILE
    if [ ! -f "$TEST_LOG_FILE" ]; then
        echo "Run TEST_UNIT: "$TEST_UNIT""
        # run TEST_UNIT
        "$TEST_UNIT" "$DATAROOT" "$DROPBOX_USERDIR" &> "$TEST_LOG_FILE"
    fi
}

# will run once before any unit test starts
setup_suite() {
    echo "setup_suite()"
    # export this variable to inform other scripts about the test mode
    export NUMB3RS_TEST=1
    rm -rf "$TEST_LOG_FILE"
    setup_local && setup_git && setup_testdata
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

    # unset variable to end test mode
    unset NUMB3RS_TEST
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

# every file except the 8epvzl83pou0.csv remains the same
test_csv_filediff_check() {
    # correct files remain as they are
    CORRECT_FILES=( $(ls "$TESTDATA"/*.csv | grep -v 8epvzl83pou0.csv) )
    for CORRFILE in "${CORRECT_FILES[@]}"
    do
        CORRFILE_NAME=$(basename "$CORRFILE")
        assert "diff <(cat "$CORRFILE") <(cat "$DATAPATH"/"$CORRFILE_NAME")"
    done
}

# 8epvzl83pou0.csv shall change
test_csv_cleanup_filediff_check() {
    CLEANUP_FILE=$(ls "$TESTDATA"/8epvzl83pou0.csv)
    CLEANUP_FILENAME=$(basename "$CLEANUP_FILE")
    assert_fail "diff <(cat "$CLEANUP_FILE") <(cat "$DATAPATH"/"$CLEANUP_FILENAME")"
}

# we expect 8epvzl83pou0.[md|xlxs] as new files
test_for_new_files_check() {
    CLEANUP_FILE=$(ls "$TESTDATA"/8epvzl83pou0.csv)
    CLEANUP_FILENAME=$(basename "$CLEANUP_FILE")
    CLEANUP_FILENAME_ONLY="${CLEANUP_FILENAME%.*}"
    # 8epvzl83pou0.[md|xlxs] must not exist in $TESTDATA dir
    assert_fail "test -f "$TESTDATA"/"${CLEANUP_FILENAME_ONLY}".md"
    assert_fail "test -f "$TESTDATA"/"${CLEANUP_FILENAME_ONLY}".xlxs"
    # 8epvzl83pou0.[md|xlxs] must exist in $DATAPATH dir
    assert "test -f "$DATAPATH"/"${CLEANUP_FILENAME_ONLY}".md"
    assert "test -f "$DATAPATH"/"${CLEANUP_FILENAME_ONLY}".xlxs"
}

# checks the timestamp change of "gateway error" file
todo_csv_timestamp_check() {
    CSV_TIMESTAMP_ORG=$(stat -c%Y $TESTDATA/8epvzl83pou0.csv)
    CSV_TIMESTAMP_CLEAN=$(stat -c%Y $DATAPATH/8epvzl83pou0.csv)
    # assert: clean is newer than old
    assert "test \"$CSV_FILESIZE_CLEAN\" -gt \"$CSV_TIMESTAMP_ORG\""
}

# checks the file size change of "gateway error" file
test_csv_filesize_check() {
    CSV_FILESIZE_ORG=$(stat -c%s $TESTDATA/8epvzl83pou0.csv)
    CSV_FILESIZE_CLEAN=$(stat -c%s $DATAPATH/8epvzl83pou0.csv)
    # assert: clean > org
    assert "test $CSV_FILESIZE_CLEAN -ne $CSV_FILESIZE_ORG"
}

# only one file should be downloaded
test_ec_download_url_count_check() {
    EC_DOWNLOAD_URL_COUNT=$(grep "Download ethercalc" "$TEST_LOG_FILE" | wc -l)
    assert "test 1 -eq "$EC_DOWNLOAD_URL_COUNT""
}
