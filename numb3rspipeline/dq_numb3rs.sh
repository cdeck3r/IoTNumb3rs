#!/bin/bash

#
# Data Quality Report for iotdata
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
# Whether it is the initial run of data quality report
INITDQ=$3
ALLUSERS=("$4")

# User's data as sqlite db
USER_DB="${DROPBOX_USERDIR}"_sqlite.db
DATATBL="iotdata"

# template for format diff
NUMB3RS_TEMPLATE="$SCRIPT_DIR"/numb3rs_template.csv
# report file
DQ_REPORT="dq.md"
SLACK_MSG_FILE="/tmp/slack_msg_dq.txt"

# error code
BCK_ERROR=0

# tools
#
GIT='git'
CSVKIT=( 'csvsql' 'csvstack' 'csvcut' 'csvstat')
DIFF='diff'

# include common funcs
source ./funcs.sh
source ./bck_funcs.sh

##############
# Helper functions
#
# returns all ethercalc URLs,
# which show the quality incident
# Param #1: Name of sqlite db file
# Param #2: SQLQUERY selecting the incident
qi_ec_url() {
    local USER_DB=$1
    local SQLQUERY=$2
    sql2csv --db sqlite:///"${USER_DB}" \
    --query "$SQLQUERY" \
    | csvsql --query "SELECT distinct src_filename from STDIN" \
    | cut -d '.' -f1 \
    | csvcut -K 1 \
    | sed 's/^/https:\/\/www.ethercalc.org\//'
}

# returns the count of ethercalc URLs
# having the quality incident
# Param #1: Name of sqlite db file
# Param #2: SQLQUERY selecting the incident
qi_sum() {
    local USER_DB=$1
    local SQLQUERY=$2
    sql2csv --db sqlite:///"${USER_DB}" \
    --query "$SQLQUERY" \
    | csvsql --query "SELECT distinct src_filename from STDIN" \
    | csvcut --skip-lines 1 | wc -l
}

# returns markdown formated enumeration of ethercalc URLs
# Param #1: number of quality incidents
# Param #2: array containing the Ethercalc URLs
qi_md_list() {
    local QI_SUM=$1
    local QI_EC_URL=("$@")
    local FIRST=0
    if [[ $QI_SUM -ne 0 ]]; then
        for EC_URL in ${QI_EC_URL[@]}
        do
            if [[ $FIRST -ne 0  ]]; then
                # we ignore first entry
                echo "1. "$EC_URL""
            else
                FIRST=1
            fi
        done
    fi
}

##############

##############
# checks

# test if csvkit is installed
for CSVTOOL in "${CSVKIT[@]}"
do
    command -v "$CSVTOOL" >/dev/null 2>&1 \
        || { log_echo "ERROR" "I require "$CSVTOOL" but it's not installed. Abort."; exit 1; }
done

command -v "$DIFF" >/dev/null 2>&1 \
    || { log_echo "ERROR" "I require "$DIFF" but it's not installed. Abort."; exit 1; }

if [ ! -f "$NUMB3RS_TEMPLATE" ]; then
    log_echo "ERROR" "Template for format diff not found. Abort."
    exit 1
fi


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

cd "$DATAROOT"

# initialize the dq report
if [[ $INITDQ -ne 0 ]]; then
    cat  << EOM > "$DQ_REPORT"
    # IoTNumb3rs Data Quality Report

EOM
    for USERDIR in $ALLUSERS
    do
    	echo "1. ["$USERDIR"](#quality-indicator-for-"$USERDIR")" >> "$DQ_REPORT"
    done
fi

# import into DB
# cut all invalid files
log_echo "INFO" "Import files into sqlite for user: "$DROPBOX_USERDIR""
csvstack --skipinitialspace --skip-lines 2 \
--linenumbers --filenames --group-name src_filename \
"${DROPBOX_USERDIR}"/*.csv \
| csvcut -c 1,2,3,4,5,6,7,8,9,10,11,12,13 \
| csvsql --db sqlite:///"${USER_DB}" --tables ${DATATBL} \
--insert --overwrite

SQLQUERY="SELECT count(*) AS data_rows FROM ${DATATBL};"
QI_DATAROWS=$(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvcut --skip-lines 1)

log_echo "INFO" "Number of available data rows for user "$DROPBOX_USERDIR": $QI_DATAROWS"

## Check

## format error

log_echo "INFO" "Check format errors for files of user: "$DROPBOX_USERDIR""
# count format incidents
QI_SUM_CSVFORMAT_ERR=0
QI_CSVFORMAT_ERR=()
for CSVFILE in "${DROPBOX_USERDIR}"/*.csvv
do
    #echo "$CSVFILE"
    VALID_HEADERS=$(csvstack --skipinitialspace --skip-lines 2 "$NUMB3RS_TEMPLATE" | csvstat --csv | csvcut -c 1,2)
    CSVFILE_HEADER=$(csvstack --skipinitialspace --skip-lines 2 "$CSVFILE" | csvstat --csv | csvcut -c 1,2)
    #echo $VALID_HEADERS
    diff <(echo $VALID_HEADERS) <(echo $CSVFILE_HEADER) > /dev/null

    FORMAT_ERR=$?
    if [[ $FORMAT_ERR -ne 0 ]]; then
        log_echo "WARN" "File format error: "$CSVFILE""
        QI_SUM_CSVFORMAT_ERR=$(($QI_SUM_CSVFORMAT_ERR + 1))
        EC_ERR=$(basename "$CSVFILE" | cut -d '.' -f1 | sed 's/^/https:\/\/www.ethercalc.org\//')
        QI_CSVFORMAT_ERR+=( "$EC_ERR" )
    else
        log_echo "INFO" "File format ok: "$CSVFILE""
    fi
done
## FIXME we don't consider format errors
QI_SUM_CSVFORMAT_ERR=0

## Quality problems
# QI: QI_SUM_EMPTYURL
log_echo "INFO" "Check data quality problems for user: "$DROPBOX_USERDIR""

SQLQUERY="SELECT * FROM "${DATATBL}" WHERE \"URL\" IS NULL;"
mapfile -t QI_EMPTYURL <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_EMPTYURL=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of empty, but mandatory URL entries: $QI_SUM_EMPTYURL"

# QI: QI_SUM_EMPTY_DROPBOX_FOLDER
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE \"Dropbox folder\" IS NULL OR \"Dropbox folder\" = \"\";"
mapfile -t QI_EMPTY_DROPBOX_FOLDER <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_EMPTY_DROPBOX_FOLDER=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of empty, but mandatory \"Dropbox folder\" entries: $QI_SUM_EMPTY_DROPBOX_FOLDER"

# QI: $QI_SUM_EMPTY_DEVICE_COUNT
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE device_count IS NULL AND device_class IS NOT NULL;"
mapfile -t QI_EMPTY_DEVICE_COUNT <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_EMPTY_DEVICE_COUNT=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of empty, but mandatory \"device_count\" entries: $QI_SUM_EMPTY_DEVICE_COUNT"

# QI: $QI_SUM_EMPTY_DEVICE_CLASS
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE device_class IS NULL AND device_count IS NOT NULL;"
mapfile -t QI_EMPTY_DEVICE_CLASS <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_EMPTY_DEVICE_CLASS=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of empty, but mandatory \"device_class\" entries: $QI_SUM_EMPTY_DEVICE_CLASS"

# QI: $QI_SUM_EMPTY_MARKET_VOLUME
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE market_volume IS NULL AND market_class IS NOT NULL;"
mapfile -t QI_EMPTY_MARKET_VOLUME <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_EMPTY_MARKET_VOLUME=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of empty, but mandatory \"market_volume\" entries: $QI_SUM_EMPTY_MARKET_VOLUME"

# QI: $QI_SUM_EMPTY_MARKET_CLASS
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE market_class IS NULL AND market_volume IS NOT NULL;"
mapfile -t QI_EMPTY_MARKET_CLASS <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_EMPTY_MARKET_CLASS=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of empty, but mandatory \"market_class\" entries: $QI_SUM_EMPTY_MARKET_CLASS"


# QI: QI_SUM_NODATA
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE device_class IS NULL AND device_count is NULL AND market_class is NULL AND market_volume is NULL AND prognosis_year is NULL AND publication_year is NULL AND authorship_class is NULL;"
mapfile -t QI_NODATA <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_NODATA=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of empty data rows: $QI_SUM_NODATA"

# QI_UNEX_DROPBOX_FOLDER
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE \"Dropbox folder\" NOT LIKE \"%"${DROPBOX_USERDIR}"%\";"
mapfile -t QI_UNEX_DROPBOX_FOLDER <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_UNEX_DROPBOX_FOLDER=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of unexpected data in \"Dropbox folder\": $QI_SUM_UNEX_DROPBOX_FOLDER"

# QI_UNEX_DEVICE_COUNT
# source: https://stackoverflow.com/a/51383461
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE device_count GLOB '*[^0-9]*' AND device_count LIKE '_%';"
mapfile -t QI_UNEX_DEVICE_COUNT <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_UNEX_DEVICE_COUNT=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of unexpected data in \"device_class\": $QI_SUM_UNEX_DEVICE_COUNT"

# QI_UNEX_MARKET_VOLUME
# source: https://stackoverflow.com/a/51383461
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE market_volume GLOB '*[^0-9]*' AND market_volume LIKE '_%';"
mapfile -t QI_UNEX_MARKET_VOLUME <<< $(qi_ec_url "${USER_DB}" "${SQLQUERY}")
QI_SUM_UNEX_MARKET_VOLUME=$(qi_sum "${USER_DB}" "${SQLQUERY}")
log_echo "INFO" "Number of unexpected data in \"market_volume\": $QI_SUM_UNEX_MARKET_VOLUME"

## Overall Quality Indicator
SQLQUERY="SELECT 1-($QI_SUM_EMPTYURL \
    + $QI_SUM_EMPTY_DROPBOX_FOLDER \
    + $QI_SUM_NODATA \
    + $QI_SUM_UNEX_DROPBOX_FOLDER \
    + $QI_SUM_CSVFORMAT_ERR \
    + $QI_SUM_UNEX_DEVICE_COUNT \
    + $QI_SUM_EMPTY_DEVICE_COUNT \
    + $QI_SUM_EMPTY_DEVICE_CLASS \
    + $QI_SUM_EMPTY_MARKET_VOLUME \
    + $QI_SUM_EMPTY_MARKET_CLASS \
    + $QI_SUM_UNEX_MARKET_VOLUME \
    )/($QI_DATAROWS+0.0)"
QI=$(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvcut --skip-lines 1)
log_echo "INFO" "Quality Indicator for "$DROPBOX_USERDIR": $QI"


# write into file
cat << EOM >> "./$DQ_REPORT"
## Quality Indicator for $DROPBOX_USERDIR

The quality indicator (Q) is 1 - #incidents/data rows.

Q = $QI

EOM

cat << EOM >> "./$DQ_REPORT"

## CSV Format Errors

Ethercalc documents contain the IoTNumb3rs project's data as csv formatted files.
Format errors may cause the exclusion of this partial data from the
data analysis.

_Solution:_ Check the Ethercalc documents and comply to the defined attributes.

*Quality incidents:* $QI_SUM_CSVFORMAT_ERR

EOM
qi_md_list $QI_SUM_CSVFORMAT_ERR "${QI_CSVFORMAT_ERR[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

## Empty URL Field

The URL field must not be empty. This data problem may occur,
if multiple figures are extracted from an infographic, but only
for the very first the infographic's URL is provided.

_Solution:_ fill up empty URL fields with the appropriate URL.

*Quality incidents:* $QI_SUM_EMPTYURL

EOM
qi_md_list $QI_SUM_EMPTYURL "${QI_EMPTYURL[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

## Empty "Dropbox folder" field

The "Dropbox folder" field must not be empty. Like the previous "Empty URL"
problem this data problem may occur, if multiple figures are extracted
from an infographic, but only for the very first the infographic's URL is provided.

_Solution:_ fill up empty "Dropbox folder" fields with the appropriate content.

*Quality incidents:* $QI_SUM_EMPTY_DROPBOX_FOLDER

EOM
qi_md_list $QI_SUM_EMPTY_DROPBOX_FOLDER "${QI_EMPTY_DROPBOX_FOLDER[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

## Empty "device_count" field

The "device_count" field must not be empty, if device_class field contains data.

_Solution:_ fill up empty "device_count" fields with the appropriate content.

*Quality incidents:* $QI_SUM_EMPTY_DEVICE_COUNT

EOM
qi_md_list $QI_SUM_EMPTY_DEVICE_COUNT "${QI_EMPTY_DEVICE_COUNT[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

## Empty "device_class" field

The "device_class" field must not be empty, if device_count field contains data.

_Solution:_ fill up empty "device_class" fields with the appropriate content.

*Quality incidents:* $QI_SUM_EMPTY_DEVICE_CLASS

EOM
qi_md_list $QI_SUM_EMPTY_DEVICE_CLASS "${QI_EMPTY_DEVICE_CLASS[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

## Empty "market_volume" field

The "market_volume" field must not be empty, if market_class field contains data.

_Solution:_ fill up empty "market_volume" fields with the appropriate content.

*Quality incidents:* $QI_SUM_EMPTY_MARKET_VOLUME

EOM
qi_md_list $QI_SUM_EMPTY_MARKET_VOLUME "${QI_EMPTY_MARKET_VOLUME[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

## Empty "market_class" field

The "market_class" field must not be empty, if market_volume field contains data.

_Solution:_ fill up empty "market_class" fields with the appropriate content.

*Quality incidents:* $QI_SUM_EMPTY_MARKET_CLASS

EOM
qi_md_list $QI_SUM_EMPTY_MARKET_CLASS "${QI_EMPTY_MARKET_CLASS[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

## No Data

Apart from the fields set automatically by the numb3rspipeline
there are no other data.

_Solution:_ Extract the data from the infographic.
If the infographic does not provide appropriate data,
then remove the entire content from the Ethercalc sheet.

*Quality incidents:* $QI_SUM_NODATA

EOM
qi_md_list $QI_SUM_NODATA "${QI_NODATA[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

## Unexpected Content

For some attributes we expect a specific form of the content.
This section investigates various attributes. An incident is found
of the attribute does not the expected content.

### Attribute: Dropbox folder

All data entries for this attribute *must* contains the
user name: $DROPBOX_USERDIR

*Quality incidents:* $QI_SUM_UNEX_DROPBOX_FOLDER

EOM
qi_md_list $QI_SUM_UNEX_DROPBOX_FOLDER "${QI_UNEX_DROPBOX_FOLDER[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

### Attribute: device_count

All data entries for this attribute *must* contains integers.

*Quality incidents:* $QI_SUM_UNEX_DEVICE_COUNT

EOM
qi_md_list $QI_SUM_UNEX_DEVICE_COUNT "${QI_UNEX_DEVICE_COUNT[@]}" >> "./$DQ_REPORT"

cat  << EOM >> "./$DQ_REPORT"

### Attribute: market_volume

All data entries for this attribute *must* contains integers.

*Quality incidents:* $QI_SUM_UNEX_MARKET_VOLUME

EOM
qi_md_list $QI_SUM_UNEX_MARKET_VOLUME "${QI_UNEX_MARKET_VOLUME[@]}" >> "./$DQ_REPORT"

# remove USER_DB
rm -rf "${USER_DB}"

# commit data quality report (dq.md )
COMMIT_FILES=""./$DQ_REPORT""
commit_push_files_dataroot_git "$DATAROOT" "$DROPBOX_USERDIR" "${COMMIT_FILES[@]}"
clean_dataroot_git "$DATAROOT"

# notify slack
echo "Quality Indicator Q: $QI" > "$SLACK_MSG_FILE"
#
exit $BCK_ERROR
