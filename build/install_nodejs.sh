#!/bin/bash

# Author: Tony Fahrion <tony.fahrion@de.clara.net>

#
# This script adds the nodejs package repo and installs nodejs and npm
# It requires that the ENV var NODEJS_VERSION is set!
#
# NOTE: it will install the latest minor version of the selected major version!
#

SUPPORTED_NODEJS_VERSIONS='6 7'
SUPPORTED_NODEJS_PACKAGE_MANAGER='npm yarn'

# different nodejs package manager have different install command arguments
# this makes using them more easily
# If you specify "yarn" as package manager, this var will be overriden later
# on.
NODEJS_PACKAGE_MANAGER_INSTALL_GLOBAL='npm install -g'


export SHOP="/data/shop"
export SETUP=spryker
export TERM=xterm 
export VERBOSITY='-v'

# include helper functions
source ./build_library.sh
source ./functions.sh

# abort on error
set -e

#
#  Prepare
#

infoText "check if we support the requested NODEJS_VERSION"
if is_not_in_list "$NODEJS_VERSION" "$SUPPORTED_NODEJS_VERSIONS"; then
  errorText "Requested NODEJS_VERSION '$NODEJS_VERSION' is not supported. Abort!"
  infoText  "Supported nodejs version is one of: $SUPPORTED_NODEJS_VERSIONS"
  exit 1
fi
successText "YES! Support is available for $NODEJS_VERSION"

infoText "check if we support the requested NODEJS_PACKAGE_MANAGER"
if is_not_in_list "$NODEJS_PACKAGE_MANAGER" "$SUPPORTED_NODEJS_PACKAGE_MANAGER"; then
  errorText "Requested NODEJS_PACKAGE_MANAGER '$NODEJS_PACKAGE_MANAGER' is not supported. Abort!"
  infoText  "Supported nodejs package manager is one of: $SUPPORTED_NODEJS_PACKAGE_MANAGER"
  exit 1
fi
successText "YES! Support is available for $NODEJS_PACKAGE_MANAGER"


infoText "set up nodejs repo to install nodejs via apt"
echo "deb https://deb.nodesource.com/node_${NODEJS_VERSION}.x xenial main" > /etc/apt/sources.list.d/nodesource.list
curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -


infoText "update apt cache to make use of the new nodejs repo"
apt-get update


#
#  Install nodejs & package manager
#

infoText "install nodejs version $NODEJS_VERSION and npm"
apt-get install $APT_GET_BASIC_ARGS --allow-unauthenticated nodejs


# install yarn if requested as package manager
if [ "$NODEJS_PACKAGE_MANAGER" == 'yarn' ]; then
  NODEJS_PACKAGE_MANAGER_INSTALL_GLOBAL='yarn global add'
  
  # see https://yarnpkg.com/en/docs/install#linux-tab
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
  apt-get update
  apt-get install $APT_GET_BASIC_ARGS yarn
fi


#
#  Install antelope
#

infoText "install antelope, which is used for assets generation"
$NODEJS_PACKAGE_MANAGER_INSTALL_GLOBAL antelope
