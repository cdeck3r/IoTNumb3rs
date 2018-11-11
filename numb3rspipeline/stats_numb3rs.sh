#!/bin/bash

#
# Scripts computes the stats
# about the students' performance for the pipeline
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

# for testing only
DATAROOT=/tmp/iotdata_bck
DROPBOX_USERDIR=testuser

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
        BCK_ERROR=1
        exit $BCK_ERROR
    fi
fi

# Update DATAROOT directory
cd "$DATAROOT"
log_echo "INFO" "Switch directory to branch <iotdata> and pull into: "$DATAROOT""
$GIT branch --set-upstream-to origin/iotdata iotdata
$GIT reset --hard # throw away all uncommited changes
$GIT checkout iotdata
$GIT pull origin iotdata

GIT_STATUS="$(git status --branch --short)"
log_echo "INFO" "Git status for "$DATAROOT" is: "$GIT_STATUS""


# prep done.

##################################

# go into user dir
cd "$DATAROOT"/"$DROPBOX_USERDIR"
DATA_FILES=( $(ls *.csv) )
URL_LST=()

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
        exit 1
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
    #UNIQ_URL_LIST=( $(echo "${URL_LST[@]}" | sort | uniq )  )
    UNIQ_URL_TOTAL_CNT="${#UNIQ_URL_LIST[@]}"
    #DUP_URL=$(($URL_CNT-$UNIQ_URL_CNT))
done

echo "============ Stats results ============"
echo User: $DROPBOX_USERDIR
#echo Data file: $DATA_FILE
echo Total data rows: $URL_TOTAL_CNT
echo Distinct Infographics: $UNIQ_URL_TOTAL_CNT
#echo DUP_URL: $DUP_URL
echo "======================================="

# Write stats file; create header first, if file does not exist
if [ ! -f "$STATS_FILE" ]; then
    echo "datetime;user;total_rows;distinct_infographics" > "$STATS_FILE"
fi
DT=$(date '+%Y-%m-%d %H:%M:%S')
echo "$DT;$DROPBOX_USERDIR;$URL_TOTAL_CNT;$UNIQ_URL_TOTAL_CNT" >> "$STATS_FILE"
