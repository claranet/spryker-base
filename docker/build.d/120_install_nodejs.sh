#!/bin/sh

#
# This script adds the nodejs package repo and installs nodejs and npm
# It requires that the ENV var NODEJS_VERSION is set!
#
# NOTE: it will install the latest minor version of the selected major version!
#

SUPPORTED_NODEJS_VERSIONS='6 7'
SUPPORTED_NODEJS_PACKAGE_MANAGER='npm yarn'


#get amount of available prozessors * 2 for faster compiling of sources
COMPILE_JOBS=$((`getconf _NPROCESSORS_ONLN`*2))

#
#  Prepare
#

if ! is_in_list "$NODEJS_VERSION" "$SUPPORTED_NODEJS_VERSIONS"; then
  errorText "NodeJS version '$NODEJS_VERSION' is not supported. Choose one of $SUPPORTED_NODEJS_VERSIONS. Abort!"
  exit 1
fi
sectionNote "NodeJS version $NODEJS_VERSION is supported"

if ! is_in_list "$NPM" "$SUPPORTED_NODEJS_PACKAGE_MANAGER"; then
  errorText "NodeJS package manager '$NPM' is not supported. Choose one of $SUPPORTED_NODEJS_PACKAGE_MANAGER. Abort!"
  exit 1
fi
sectionNote "NodeJS package manager '$NPM' is supported"


#
#  Install nodejs & package manager
#

sectionNote "install nodejs version $NODEJS_VERSION"
if [ "$NODEJS_VERSION" = "7" ]; then
  $apk_add nodejs-current
else
  $apk_add nodejs
fi


# install yarn if requested as package manager
if [ "$NPM" = 'yarn' ]; then
  sectionNote "install $NPM"
  $apk_add yarn
fi
