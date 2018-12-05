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

## Check

## format error

log_echo "INFO" "Check format errors for files of user: "$DROPBOX_USERDIR""
csvstack --skipinitialspace --skip-lines 2 \
--linenumbers --filenames \
"${DROPBOX_USERDIR}"/*.csv \
| csvstat -c 1-13

FORMAT_ERR=$?
if [[ $FORMAT_ERR -ne 0 ]]; then
    log_echo "WARN" "Format error in file of user: "$DROPBOX_USERDIR""
fi

## Quality problems
# QI: SUM_EMPTYURL
log_echo "INFO" "Check data quality problems for user: "$DROPBOX_USERDIR""


sql2csv --db sqlite:///"${USER_DB}" \
--query "SELECT * FROM "${DATATBL}" WHERE \"URL\" IS NULL;" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| cut -d '.' -f1 \
| csvcut -K 1 \
| sed 's/^/https:\/\/www.ethercalc.org\//'

SUM_EMPTYURL=$(sql2csv --db sqlite:///"${USER_DB}" \
--query "SELECT * FROM "${DATATBL}" WHERE \"URL\" IS NULL;" \
| csvsql --query "SELECT distinct src_filename from STDIN" \
| csvcut --skip-lines 1 | wc -l)

log_echo "INFO" "Empty URLs: $SUM_EMPTYURL"

#

# remove USER_DB
#rm -rf "${USER_DB}"
