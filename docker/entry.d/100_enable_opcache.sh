#!/bin/sh
ext=opcache
if is_true $ENABLE_OPCACHE; then
  sectionText "Enabling PHP extension $ext"
  docker-php-ext-enable $ext >> $BUILD_LOG 2>&1
else
  sectionText "Disabling PHP extension $ext"
  file="/usr/local/etc/php/conf.d/docker-php-ext-opcache.ini"
  [ -e $file ] && rm $file
fi
