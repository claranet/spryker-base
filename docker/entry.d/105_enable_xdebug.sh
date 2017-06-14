#!/bin/sh
ext=xdebug
if is_true $ENABLE_XDEBUG; then
  sectionText "Enabling PHP extension $ext"
  docker-php-ext-enable $ext
  mkdir -pv /tmp/$ext
  chmod -v 7777 /tmp/$ext
else
  sectionText "Disabling PHP extension $ext"
  file="/usr/local/etc/php/conf.d/docker-php-ext-$ext.ini"
  [ -e $file ] && rm $file
fi >> $BUILD_LOG 2>&1
return 0
