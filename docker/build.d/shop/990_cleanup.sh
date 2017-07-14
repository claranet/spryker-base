#!/bin/sh

skip_cleanup && return 0

#apk del .build_deps || true 
if [ -e /var/tmp/build-deps.list ]; then
  sectionText "Removing build depedencies"
  cat /var/tmp/build-deps.list | xargs apt-get remove --purge -y || true >> $BUILD_LOG
  rm -f /var/tmp/build-deps.list
  apt-get autoremove -y
fi

sectionText "Cleaning up /tmp folder"
rm -rf /tmp/*

sectionText "Removing apk package index files"
#find /var/cache/apk  -type f -exec rm {} \;

sectionText "Compressing docker build log"
gzip $BUILD_LOG
