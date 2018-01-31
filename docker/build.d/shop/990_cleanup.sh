#!/bin/sh

skip_cleanup && return 0

sectionText "Removing optional os packages"
echo $BUILD_DEPS
apt-get remove -y $BUILD_DEPS >> $BUILD_LOG

sectionText "Cleaning up /tmp folder"
rm -rf /tmp/*

sectionText "Removing apt cache and lists"
rm -rf /var/chache/apt/*
rm -rf /var/lib/apt/lists/*

sectionText "Compressing docker build log"
gzip $BUILD_LOG
