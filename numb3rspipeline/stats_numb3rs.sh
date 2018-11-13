#!/bin/bash

#
# Scripts computes stats from the backup data
# to reason about the students' performance when using the pipeline
#

# this directory is the script directory
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPT_DIR

#
# vars and params
#

# the script's name
SCRIPT_NAME=$0
# this directory stores result of all runs, e.g. /tmp/iotdata
DATAROOT=$1
# the name of the dropbox directory where the url_list is found
DROPBOX_USERDIR=$2

# stats output file
STATS_FILE="$DATAROOT/stats.csv"

#
# tools
#
GIT='git'
DB_UPLOADER='../Dropbox-Uploader/dropbox_uploader.sh'
CURL='curl'

# include common funcs
source ./funcs.sh

# prep dir
mkdir -p "$DATAROOT"
cd "$DATAROOT"
$GIT status
if [[ $? -eq 128 ]]; then
    log_echo "WARN" "Data directory is not in git: "$DATAROOT""
    log_echo "INFO" "Clone branch <iotdata> in "$DATAROOT""
    # one dir up, e.g. /tmp
    cd "$(dirname "$DATAROOT")"
    # ... and clone branch iodata into ./iotdata
    $GIT clone https://github.com/cdeck3r/IoTNumb3rs.git \
    --branch iotdata \
    --single-branch \
    $(basename "$DATAROOT")
    if [[ $? -ne 0 ]]; then
        log_echo "ERROR" "GIT does not work. Abort."
        ERR_CODE=1
        exit $ERR_CODE
    fi
fi

# Update DATAROOT directory
cd "$DATAROOT"
log_echo "INFO" "Switch directory to branch <iotdata> and pull into: "$DATAROOT""
$GIT branch --set-upstream-to origin/iotdata iotdata
$GIT reset --hard # throw away all uncommited changes
$GIT checkout iotdata
$GIT pull origin iotdata

cd "$DATAROOT"
GIT_STATUS="$(git status --branch --short)"
log_echo "INFO" "Git status for "$DATAROOT" is: ${GIT_STATUS}"

# prep done.

##################################

# go into user dir
cd "$DATAROOT"/"$DROPBOX_USERDIR"
DATA_FILES=( $(ls *.csv) )
URL_LST=()

# we start with error,
# which needs to be reset after the 1st Successful run
ERR_CODE=1
for DATA_FILE in ${DATA_FILES[@]}
do
    HDR_MATCH="URL,*" # pattern to match
    LINE_CNT=0
    HEADER_LINE=
    # find header line
    while IFS='' read -r HDR_STR || [[ -n "$HDR_STR" ]]; do
        # some preps; removes newline
        HDR_STR=$(echo "$HDR_STR" | tr -d '\n' | tr -d '\r')
        # test if URL_STR is empty (= fake lines)
        if [[ -z "$HDR_STR" ]]; then
            continue
        fi

        LINE_CNT=$((LINE_CNT + 1))
        if [[ "$HDR_STR" == ${HDR_MATCH} ]]; then
            log_echo "INFO" "Header found in "$LINE_CNT" of data file: "$DATA_FILE""
            HEADER_LINE=$LINE_CNT
        fi
    done < "$DATA_FILE"

    if [[ -z $HEADER_LINE ]]; then
        log_echo "ERROR" "Header line not found in data file: "$DATA_FILE""
        # implements ERR_CODE &= ERR_CODE
        # ERR_CODE remains 1 iff it was never 0
        if [[ $ERR_CODE -eq 0 ]]; then
            ERR_CODE=0
        else
            ERR_CODE=1
        fi
        continue # next DATA_FILE
    fi

    FIRST_DATA_LINE=$((HEADER_LINE + 1))
    readarray DATA_ROWS <<< $(tail +${FIRST_DATA_LINE} "$DATA_FILE")
    for ROW in ${DATA_ROWS[@]}
    do
        if [[ $ROW == "http"* ]]; then
            URL_LST+=( $(echo $ROW | cut -d ',' -f1) )
        fi
    done

    URL_TOTAL_CNT="${#URL_LST[@]}"
    IFS=$'\n'
    UNIQ_URL_LIST=($(sort -u <<<"${URL_LST[*]}"))
    unset IFS
    UNIQ_URL_TOTAL_CNT="${#UNIQ_URL_LIST[@]}"

    ERR_CODE=0
done

# fatal failure: no stats data at all
if [[ $ERR_CODE -eq 1 ]]; then
    log_echo "ERROR" "Could not compute stats data for user: "$DROPBOX_USERDIR""
    exit $ERR_CODE
fi

echo "============ Stats results ============"
echo User: $DROPBOX_USERDIR
#echo Data file: $DATA_FILE
echo Total data rows: $URL_TOTAL_CNT
echo Distinct Infographics: $UNIQ_URL_TOTAL_CNT
echo "======================================="

# Write stats file; create header first, if file does not exist
if [ ! -f "$STATS_FILE" ]; then
    echo "datetime;user;total_rows;distinct_infographics" > "$STATS_FILE"
fi
DT=$(date '+%Y-%m-%d %H:%M:%S')
echo "$DT;$DROPBOX_USERDIR;$URL_TOTAL_CNT;$UNIQ_URL_TOTAL_CNT" >> "$STATS_FILE"
ERR_CODE=0

# add STATS_FILE to repo
cd "$DATAROOT"
GIT_STATUS="$(git status --branch --short)"
log_echo "INFO" "Git status for "$DATAROOT" is: "$GIT_STATUS""

# set remote url containing token var
# each time git is used, the var should be replaced by its current value
$GIT remote set-url --push origin https://${GITHUB_OAUTH_ACCESS_TOKEN}@github.com/cdeck3r/IoTNumb3rs.git
$GIT config user.name "Christian Decker"
$GIT config user.email "christian.decker@reutlingen-university.de"

# add everything into repo
# push using github token
$GIT add $(basename $STATS_FILE)
$GIT commit -m "Update statistics for user "$DROPBOX_USERDIR"" $(basename $STATS_FILE)
$GIT push
# Final error / info logging
if [[ $? -ne 0 ]]; then
    log_echo "ERROR" "Error pushing data into branch <iotdata> on Github."
    ERR_CODE=1
else
    log_echo "INFO" "Successfully pushed data into branch <iotdata> on Github."
fi
# revert to original URL in order to avoid token to be stored
$GIT remote set-url --push origin "https://github.com/cdeck3r/IoTNumb3rs.git"

exit $ERR_CODE
