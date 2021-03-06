#!/bin/bash

#
# contains common funcs for bck_* scripts
#

# include common funcs
source ./funcs.sh

if [ -z "${NUMB3RS_TEST+x}" ]; then
    # we are in regular operation mode
    DATA_BRANCH="iotdata"
else
    # we are in test mode
    DATA_BRANCH="iotdata-test"
fi

if [ -z "${GIT+x}" ]; then
    # if GIT is unset, set it default
    GIT='git'
fi

# test if git is installed
command -v "$GIT" >/dev/null 2>&1 \
    || { echo >&2 "I require "$GIT" but it's not installed.  Aborting."; exit 1; }

# Test if Github access token is defined
if [ -z "${GITHUB_OAUTH_ACCESS_TOKEN+x}" ]; then
    log_echo "WARN" "Github OATH access token not set. No push possible."
fi

#
# clone DATAROOT directory from repo
#
# Param #1: DATAROOT directory
clone_dataroot_git() {
    local DATAROOT=$1
    mkdir -p "$DATAROOT"
    cd "$DATAROOT"
    $GIT status
    if [[ $? -eq 128 ]]; then
        log_echo "WARN" "Data directory is not in git: "$DATAROOT""
        log_echo "INFO" "Clone branch <"$DATA_BRANCH"> in "$DATAROOT""
        # one dir up, e.g. /tmp
        cd "$(dirname "$DATAROOT")"
        # ... and clone branch iodata into ./iotdata
        $GIT clone https://github.com/cdeck3r/IoTNumb3rs.git \
        --branch "$DATA_BRANCH" \
        --single-branch \
        $(basename "$DATAROOT")
        if [[ $? -ne 0 ]]; then
            log_echo "ERROR" "GIT does not work. Abort."
            BCK_ERROR=1
            exit $BCK_ERROR
        fi
    fi
}

#
# update and configure DATAROOT directory
#
# Param #1: DATAROOT directory
update_config_dataroot_git() {
    local DATAROOT=$1
    # Update DATAROOT directory
    cd "$DATAROOT"
    log_echo "INFO" "Switch directory to branch <"$DATA_BRANCH"> and pull into: "$DATAROOT""
    $GIT branch --set-upstream-to origin/"$DATA_BRANCH" "$DATA_BRANCH"
    $GIT reset --hard # throw away all uncommited changes
    $GIT checkout "$DATA_BRANCH"
    $GIT pull origin "$DATA_BRANCH"

    GIT_STATUS="$(git status --branch --short)"
    log_echo "INFO" "Git status for "$DATAROOT" is: "$GIT_STATUS""

    # set remote url containing token var
    # each time git is used, the var should be replaced by its current value
    $GIT remote set-url --push origin https://${GITHUB_OAUTH_ACCESS_TOKEN}@github.com/cdeck3r/IoTNumb3rs.git
    $GIT config user.name "Christian Decker"
    $GIT config user.email "christian.decker@reutlingen-university.de"
}

#
# update README.md file in DATAROOT directory
# to track progress
#
# Param #1: DATAROOT directory
# Param #2: DROPBOX_USERDIR
update_readme_dataroot_git() {
    local DATAROOT=$1
    local DROPBOX_USERDIR=$2
    local DATAPATH="$DATAROOT"/"$DROPBOX_USERDIR"
    # need to switch to DATAROOT to add / commit / push all data
    cd "$DATAROOT"
    GIT_STATUS="$(git status --branch --short)"
    log_echo "INFO" "Git status for "$DATAROOT" is: "$GIT_STATUS""
    # update README.md, if necessary
    GIT_FILES=
    GIT_FILES="$(git status --short)"
    if [[ -z $GIT_FILES ]]; then
        log_echo "INFO" "No new files to be added for git."
        BCK_ERROR=20
    else
        echo " " >> "$DATAROOT"/README.md
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S,%s');" \
            "User: $DROPBOX_USERDIR;" \
            "Files: $(ls -l $DATAPATH | wc -l )" >> "$DATAROOT"/README.md
    fi
}

#
# commit and push files in DATAROOT directory
#
# Param #1: DATAROOT directory
# Param #2: DROPBOX_USERDIR
commit_push_dataroot_git() {
    local DATAROOT=$1
    local DROPBOX_USERDIR=$2

    # go into DATAROOT
    cd "$DATAROOT"
    # add everything into repo
    # push using github token
    $GIT add *
    $GIT commit -m "Backup IoTNumb3rs data for user "$DROPBOX_USERDIR""
    $GIT push
    # Final error / info logging
    if [[ $? -ne 0 ]]; then
        log_echo "ERROR" "Error pushing data into branch <"$DATA_BRANCH"> on Github."
        BCK_ERROR=1
    else
        log_echo "INFO" "Successfully pushed data into branch <"$DATA_BRANCH"> on Github."
    fi
    # revert to original URL in order to avoid token to be stored
    $GIT remote set-url --push origin "https://github.com/cdeck3r/IoTNumb3rs.git"
}

#
# commit and push specified files in DATAROOT directory
#
# Param #1: DATAROOT directory
# Param #2: DROPBOX_USERDIR
# Param #3: COMMIT_FILES
# Param #4: (optional) COMMIT_MSG
commit_push_files_dataroot_git() {
    local DATAROOT=$1
    local DROPBOX_USERDIR=$2
    local COMMIT_FILES=("$3")
    local COMMIT_MSG=$4

    # go into DATAROOT
    cd "$DATAROOT"
    # add COMMIT_FILES and push using github token
    for CFILE in $COMMIT_FILES
    do
        $GIT add "$CFILE"
    done

    # if param not set; set default msg
    if [ -z "${COMMIT_MSG+x}" ]; then
        COMMIT_MSG="Adding IoTNumb3rs data for user "$DROPBOX_USERDIR""
    fi
    $GIT commit -m "$COMMIT_MSG"
    $GIT push
    # Final error / info logging
    if [[ $? -ne 0 ]]; then
        log_echo "ERROR" "Error pushing data into branch <"$DATA_BRANCH"> on Github."
        BCK_ERROR=1
    else
        log_echo "INFO" "Successfully pushed data into branch <"$DATA_BRANCH"> on Github."
        #BCK_ERROR=0
    fi
    # revert to original URL in order to avoid token to be stored
    $GIT remote set-url --push origin "https://github.com/cdeck3r/IoTNumb3rs.git"
}

# removes untracked files from DATAROOT directory
#
# Param #1: DATAROOT directory
clean_dataroot_git() {
    local DATAROOT=$1
    # go into DATAROOT
    cd "$DATAROOT"
    $GIT clean -f
    if [[ $? -ne 0 ]]; then
        log_echo "ERROR" "GIT could not clean directory: "$DATAROOT""
    fi
}
