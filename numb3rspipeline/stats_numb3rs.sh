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
# template for ethercalc format
NUMB3RS_TEMPLATE="$SCRIPT_DIR"/numb3rs_template.csv
NUMB3RS_TEMPLATE_FILESIZE=$(stat -c %s "$NUMB3RS_TEMPLATE")
#
# tools
#
GIT='git'

# include common funcs
source ./funcs.sh
source ./bck_funcs.sh

##############

# prepare DATAROOT directory
log_echo "INFO" "Prepare backup data directory: "$DATAROOT""
clone_dataroot_git "$DATAROOT"
update_config_dataroot_git "$DATAROOT"
clean_dataroot_git "$DATAROOT"
log_echo "INFO" "All preps done for branch <iotdata> in directory: "$DATAROOT""
# back to where you come from
cd "$SCRIPT_DIR"

##################################

# create & goto into DATAPATH (= user specific dir)
DATAPATH="$DATAROOT"/"$DROPBOX_USERDIR"
mkdir -p "$DATAPATH"
cd "$DATAPATH"
log_echo "INFO" "Processing user data directory: "$DATAPATH""

##################################

# go into user dir; find all .csv files larger than template file
cd "$DATAPATH"
DATA_FILES=( $(find . -name '*.csv' -type f -size +${NUMB3RS_TEMPLATE_FILESIZE}c) )

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
    readarray DATA_ROWS <<< $(tail -n +${FIRST_DATA_LINE} "$DATA_FILE")
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
# commit data quality report (dq.md )
BCK_ERROR=$ERR_CODE
COMMIT_FILES=""$STATS_FILE""
commit_push_files_dataroot_git "$DATAROOT" \
    "$DROPBOX_USERDIR" "${COMMIT_FILES[@]}" \
    "Update statistics for user "$DROPBOX_USERDIR""
ERR_CODE=$BCK_ERROR
clean_dataroot_git "$DATAROOT"

exit $ERR_CODE
