#!/bin/sh

finish_build_steps() {
  # fix error with missing event log dir
  # TODO: configure log destination to /data/logs/
  sectionNote "create required directories for logs"
  mkdir -p $WORKDIR/data/$SPRYKER_SHOP_CC/logs/ZED

  # TODO: increase security by making this more granular
  sectionNote "fix owner properties for files within /data/"
  chown -R www-data: /data/logs $WORKDIR/data
  
  if [ "$DEV_TOOLS" = "on" ]; then
    sectionNote "install ops tools"
    install_packages vim less tree
  else
    sectionHeadline "cleaning up the image"
    
    sectionNote "remove optional os packages"
    apk del .build_deps
    
    REMOVEABLE_LIST=`find $WORKDIR/vendor -type d -name 'node_modules'`
    REMOVEABLE_LIST="/root/.npm $WORKDIR/node_modules $WORKDIR/package.json $WORKDIR/package.lock /root/.composer /usr/bin/composer.phar $REMOVEABLE_LIST"
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
}

FINISHING_TASKS="$FINISHING_TASKS finish_build_steps"
