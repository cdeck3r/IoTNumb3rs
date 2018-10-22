#!/bin/bash

#
# slackr
# Simple shell command to send or pipe content to slack via webhooks.
#
git clone https://github.com/a-sync/slackr.git
cd slackr && chmod +x slackr

# back
cd ..

#
#
# Dropbox Uploader is a BASH script which can be used to upload,
# download, list or delete files from Dropbox, an online file sharing,
# synchronization and backup service.
# https://www.andreafabrizi.it/2016/01/01/Dropbox-Uploader/
git clone https://github.com/andreafabrizi/Dropbox-Uploader.git
cd Dropbox-Uploader
chmod +x dropbox_uploader.sh
cd ..
