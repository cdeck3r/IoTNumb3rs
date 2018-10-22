#!/bin/bash

#
# This installs various system software
# It should run on any ubuntu like linux server
#
# Author: Christian Decker (cdeck3r)
#
if [[ $EUID > 0 ]]
  then echo "Please run as root, e.g. sudo -E $0"
  exit 1
fi


# install java
apt-get -y update

# install curl
apt-get install -y curl

# install tools
apt-get install -y git \
    build-essential

# install python
apt-get install -y python \
    python-dev \
    python-pip
# check pip
python -m ensurepip && \
    pip install --upgrade pip setuptools
# install virtualenv using pip
pip install virtualenv

# install tesseract
apt-get install -y tesseract-ocr
