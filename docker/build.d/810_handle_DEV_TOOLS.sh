#!/bin/sh

if [ "$DEV_TOOLS" = "on" ]; then
  sectionText "install ops tools"
  install_packages vim less tree
else
  sectionHead "cleaning up the image"
  
  sectionText "remove optional os packages"
  apk del .build_deps
  
  REMOVEABLE_LIST=`find $WORKDIR/vendor -type d -name 'node_modules'`
  REMOVEABLE_LIST="/root/.npm $WORKDIR/node_modules $WORKDIR/package.json $WORKDIR/package.lock /root/.composer /usr/bin/composer.phar $REMOVEABLE_LIST"
  for removeable in $REMOVEABLE_LIST; do
    if [ -e $removeable ]; then
      sectionText "remove $removeable"
      rm -rf $removeable
    fi
  done
  
  sectionText "clean up /tmp folder"
  rm -rf /tmp/*
  
  sectionText "remove apk package index files"
  rm /var/cache/apk/*
  
  sectionText "compress docker build log"
  gzip $BUILD_LOG
fi
