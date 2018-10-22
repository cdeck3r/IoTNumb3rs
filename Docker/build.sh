#!/bin/sh

#
# Builds the IoTNumb3rs Docker image
#
# Author: Christian Decker (cdeck3r)
#

echo Building TA base [iotnumb3rs:latest]
TARGET=latest

docker build --force-rm --rm --no-cache \
    -t iotnumb3rs:$TARGET . \
    -f Dockerfile &&

# remove dangling images if build failed
docker rmi -f $(docker images --quiet --filter "dangling=true")
