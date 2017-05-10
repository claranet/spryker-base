#!/bin/sh

if [ "$DEV_TOOLS" = "on" ]; then
  sectionNote "install ops tools"
  install_packages vim less tree
else
  sectionHeadline "cleaning up the image"
  
  sectionNote "remove optional os packages"
  apk del .build_deps
  
  REMOVEABLE_LIST=`find $WORKDIR/vendor -type d -name 'node_modules'`
  REMOVEABLE_LIST="/root/.npm $WORKDIR/node_modules $WORKDIR/package.json $WORKDIR/package.lock $REMOVEABLE_LIST"
  for removeable in $REMOVEABLE_LIST; do
    if [ -e $removeable ]; then
      sectionNote "remove $removeable"
      rm -rf $removeable
    fi
  done
  
  sectionNote "clean up /tmp folder"
  rm -rf /tmp/*
  
  sectionNote "remove apk package index files"
  rm /var/cache/apk/*
  
  sectionNote "compress docker build log"
  gzip $BUILD_LOG
fi
