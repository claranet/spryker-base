#!/bin/sh

if is_true $ENABLE_XDEBUG; then
  sectionText "Enable PHP extension xdebug"
  docker-php-ext-enable xdebug
  mkdir -pv /tmp/xdebug
  chmod -v 7777 /tmp/xdebug
fi >> $BUILD_LOG 2>&1
