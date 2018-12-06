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

# User's data as sqlite db
USER_DB="${DROPBOX_USERDIR}"_sqlite.db
DATATBL="iotdata"

# tools
#
GIT='git'
CSVKIT=( 'csvsql' 'csvstack' 'csvcut' 'csvstat')

# include common funcs
source ./funcs.sh
source ./bck_funcs.sh

##############
#
# returns all ethercalc URLs,
# which show the quality incident
# Param #1: SQLQUERY selecting the incident
qi_ec_url() {
    echo "dummy"
}

# returns the count of ethercalc URLs
# having the quality incident
# Param #1: SQLQUERY selecting the incident
qi_sum() {
    echo "dummy"
}


# test if csvkit is installed
for CSVTOOL in "${CSVKIT[@]}"
do
    command -v "$CSVTOOL" >/dev/null 2>&1 \
        || { log_echo "ERROR" "I require "$CSVTOOL" but it's not installed. Abort."; exit 1; }
done

# prepare DATAROOT directory
log_echo "INFO" "Prepare backup data directory: "$DATAROOT""
clone_dataroot_git "$DATAROOT"
update_config_dataroot_git "$DATAROOT"
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

for CSVFILE in "${DROPBOX_USERDIR}"/*.csv
do
    #echo "$CSVFILE"
    csvstack --skipinitialspace --skip-lines 2 \
    "$CSVFILE" \
    | csvstat --columns URL,home_url,filename,device_class,device_count,market_class,market_volume,prognosis_year,publication_year,authorship_class,"Dropbox folder" > /dev/null

    FORMAT_ERR=$?
    if [[ $FORMAT_ERR -ne 0 ]]; then
        log_echo "WARN" "File format error: "$CSVFILE""
    fi
done

## Quality problems
# QI: QI_SUM_EMPTYURL
log_echo "INFO" "Check data quality problems for user: "$DROPBOX_USERDIR""

SQLQUERY="SELECT * FROM "${DATATBL}" WHERE \"URL\" IS NULL;"
mapfile -t QI_EMPTYURL <<< $(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| cut -d '.' -f1 \
| csvcut -K 1 \
| sed 's/^/https:\/\/www.ethercalc.org\//')

QI_SUM_EMPTYURL=$(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| csvcut --skip-lines 1 | wc -l)

log_echo "INFO" "Number of empty, but mandatory URL entries: $QI_SUM_EMPTYURL"

# QI: QI_SUM_EMPTY_DROPBOX_FOLDER
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE \"Dropbox folder\" IS NULL OR \"Dropbox folder\" = \"\";"
mapfile -t QI_EMPTY_DROPBOX_FOLDER <<< $(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| cut -d '.' -f1 \
| csvcut -K 1 \
| sed 's/^/https:\/\/www.ethercalc.org\//')

QI_SUM_EMPTY_DROPBOX_FOLDER=$(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| csvcut --skip-lines 1 | wc -l)

log_echo "INFO" "Number of empty, but mandatory \"Dropbox folder\" entries: $QI_SUM_EMPTY_DROPBOX_FOLDER"

# QI: QI_SUM_NODATA
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE device_class IS NULL AND device_count is NULL AND market_class is NULL AND market_volume is NULL AND prognosis_year is NULL AND publication_year is NULL AND authorship_class is NULL;"
mapfile -t QI_NODATA <<< $(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| cut -d '.' -f1 \
| csvcut -K 1 \
| sed 's/^/https:\/\/www.ethercalc.org\//')

QI_SUM_NODATA=$(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| csvcut --skip-lines 1 | wc -l)
log_echo "INFO" "Number of empty data rows: $QI_SUM_NODATA"

# QI_UNEX_DROPBOX_FOLDER
SQLQUERY="SELECT * FROM "${DATATBL}" WHERE \"Dropbox folder\" NOT LIKE \"%"${DROPBOX_USERDIR}"%\";"
mapfile -t QI_UNEX_DROPBOX_FOLDER <<< $(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| cut -d '.' -f1 \
| csvcut -K 1 \
| sed 's/^/https:\/\/www.ethercalc.org\//')

QI_SUM_UNEX_DROPBOX_FOLDER=$(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| csvcut --skip-lines 1 | wc -l)
log_echo "INFO" "Number unexpected data in \"Dropbox folder\": $QI_SUM_UNEX_DROPBOX_FOLDER"


## Overall Quality Indicator
SQLQUERY="SELECT 1-($QI_SUM_EMPTYURL + $QI_SUM_EMPTY_DROPBOX_FOLDER + $QI_SUM_NODATA + $QI_SUM_UNEX_DROPBOX_FOLDER)/($QI_DATAROWS+0.0)"
QI=$(sql2csv --db sqlite:///"${USER_DB}" \
--query "$SQLQUERY" \
| csvcut --skip-lines 1)
log_echo "INFO" "Quality Indicator for "$DROPBOX_USERDIR": $QI"


# write into file
cat << EOM
## Quality Indicator for $DROPBOX_USERDIR

The quality indicator (Q) is 1 - #incidents/data rows.

Q = $QI

EOM

cat  << EOM
## Empty URL Field

The URL field must not be empty. This data problem may occur,
if multiple figures are extracted from an infographic, but only
for the very first the infographic's URL is provided.

_Solution:_ fill up empty URL fields with the appropriate URL.

*Quality incidents:* $QI_SUM_EMPTYURL

EOM

cat  << EOM
## Empty "Dropbox folder" field

The "Dropbox folder" field must not be empty. Like the previous "Empty URL"
problem This data problem may occur, if multiple figures are extracted
from an infographic, but only for the very first the infographic's URL is provided.

_Solution:_ fill up empty "Dropbox folder" fields with the appropriate content.

*Quality incidents:* $QI_SUM_EMPTY_DROPBOX_FOLDER

EOM


cat  << EOM
## No Data

Apart from the fields set automatically by th enumb3rspipeline
there are no other data.

_Solution:_ Extract the data from the infographic.
If the infographic does not provide appropriate data,
then remove the entire content from the Ethercalc sheet.

*Quality incidents:* $QI_SUM_NODATA

EOM

cat  << EOM
## Unexpected Content

For some attributes we expect a specific form of the content.
This section investigates various attributes. An incident is found
of the attribute does not the expected content.

### Attribute: Dropbox folder

All data entries for this attribute *must* contains the
user name: $DROPBOX_USERDIR

*Quality incidents:* $QI_SUM_UNEX_DROPBOX_FOLDER

EOM
#

# remove USER_DB
#rm -rf "${USER_DB}"
