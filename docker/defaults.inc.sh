#!/bin/sh

#
#  General
#
APPLICATION_ENV="production"
DEV_TOOLS="off"

BUILD_LOG=/data/logs/build.log

#
#  NodeJS defaults
#
NODEJS_VERSION="6" # nodejs major 6 or 7 are supported
NPM=npm            # npm or yarn are supported

#
#  PHP defaults
#
# pecl extensions
PHP_EXTENSION_IMAGICK="3.4.3"
PHP_EXTENSION_REDIS="3.1.2"
