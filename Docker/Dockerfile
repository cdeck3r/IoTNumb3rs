FROM alpine:3.8

#
# Image for the IoTNumb3rs project
# Note: does not comply to best practises for writing Dockerfiles
#
# See: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
# for improvements
#
MAINTAINER cdeck3r

USER root

#
# add a regular user
#
ENV IOT_USER=iot \
	IOT_UID=1000 \
	IOT_GROUP=iot \
	IOT_GID=1000

RUN addgroup -g $IOT_GID -S $IOT_GROUP && \
	adduser -u $IOT_UID -S $IOT_USER -G $IOT_GROUP

#
# install gcc
#
RUN apk add --no-cache \
	build-base

#
# We use OpenJDK instead of OracleJDK.
#
# Alternative apline docker image using OracleJDK
# https://hub.docker.com/r/anapsix/alpine-java/
#

##
# Taken from ???
#

# A few reasons for installing distribution-provided OpenJDK:
#
#  1. Oracle.  Licensing prevents us from redistributing the official JDK.
#
#  2. Compiling OpenJDK also requires the JDK to be installed, and it gets
#     really hairy.
#
#     For some sample build times, see Debian's buildd logs:
#       https://buildd.debian.org/status/logs.php?pkg=openjdk-8

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk/jre
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_VERSION 8u151
#ENV JAVA_ALPINE_VERSION 8.151.12-r0
ENV JAVA_ALPINE_VERSION 8.181.13-r0

RUN set -x \
	&& apk add --no-cache \
		openjdk8-jre="$JAVA_ALPINE_VERSION" \
&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

#
# Install software: curl
#
RUN apk add --no-cache curl && \
	mkdir -p /opt

#
# Install software: bash, git openssh, zlib
#
RUN apk add --no-cache \
	bash \
	git \
	openssh

#
# Install software for image processing
#
RUN apk add --no-cache \
	zlib \
	zlib-dev \
	libjpeg \
	tiff \
	tiff-dev \
	libwebp \
	openjpeg

#
# Install tesseract
#
RUN apk add --no-cache \
	tesseract-ocr

#
# Install python, virtualenv
#
RUN apk add --no-cache \
	python \
	python-dev && \
    python -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools wheel && \
	pip install virtualenv && \
rm -r /root/.cache

#RUN apk add --no-cache \
#	python \
#	python-dev \
#	py-pip && \
#    python -m ensurepip && \
#    rm -r /usr/lib/python*/ensurepip && \
#    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
#    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
#	pip install --no-cache-dir -U pip setuptools && \
#	pip install --no-cache-dir -U setuptools virtualenv && \
#	rm -rf /root/.cache

#
# Switch to user
#
WORKDIR /home/$IOT_USER
USER $IOT_USER

#
# Place holder to add artifacts specific to the user
#COPY install_supplementals.sh .
#RUN ./install_supplementals.sh

ENTRYPOINT ["/bin/bash"]
