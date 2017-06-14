#!/bin/sh
ext=opcache
if is_true $ENABLE_OPCACHE; then
  sectionText "Enable PHP extension $ext"
  docker-php-ext-enable $ext >> $BUILD_LOG 2>&1
fi
