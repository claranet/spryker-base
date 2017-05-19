#!/bin/sh

sectionText "Cleaning up /tmp folder"
rm -rf /tmp/*

sectionText "Removing apk package index files"
find /var/cache/apk  -type f -exec rm {} \;
