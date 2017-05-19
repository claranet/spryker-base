#!/bin/sh

sectionText "Removing build depedencies"
apk del .build_deps || true

sectionText "Cleaning up /tmp folder"
rm -rf /tmp/*

sectionText "Removing apk package index files"
find /var/cache/apk  -type f -exec rm {} \;
