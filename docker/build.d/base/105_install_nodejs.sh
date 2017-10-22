#!/bin/sh
#
# This script adds the nodejs package repo and installs nodejs and npm
# It requires that the ENV var NODEJS_VERSION is set!
#
# NOTE: it will install the latest minor version of the selected major version!

SUPPORTED_NODEJS_VERSIONS='6 7'
SUPPORTED_NODEJS_PACKAGE_MANAGER='npm yarn'

#
# Sanity Check
#
if ! is_in_list "$NODEJS_VERSION" "$SUPPORTED_NODEJS_VERSIONS"; then
  errorText "NodeJS version '$NODEJS_VERSION' is not supported."
  errorText "Choose one of $SUPPORTED_NODEJS_VERSIONS. Aborting!"
  exit 1
fi
sectionText "NodeJS version $NODEJS_VERSION is supported"

if ! is_in_list "$NPM" "$SUPPORTED_NODEJS_PACKAGE_MANAGER"; then
  errorText "NodeJS package manager '$NPM' is not supported."
  errorText "Choose one of $SUPPORTED_NODEJS_PACKAGE_MANAGER. Aborting!"
  exit 1
fi
sectionText "NodeJS package manager '$NPM' is supported"


#
#  Install nodejs & package manager
#
sectionText "Install nodejs version $NODEJS_VERSION"

if is_alpine; then 
  if [ "$NODEJS_VERSION" = "7" ]; then
    install_packages nodejs-current
  else
    install_packages nodejs
  fi

  # install yarn if requested as package manager
  if [ "$NPM" = 'yarn' ]; then
    sectionText "Install $NPM"
    install_packages yarn
  fi

elif is_debian; then
  curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash -
  install_packages nodejs

fi
