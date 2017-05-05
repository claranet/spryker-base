#!/bin/sh

# install dependencies for building asset
# --with-dev is required to install spryker/oryx (works behind npm run x)
infoText "Installing required NPM dependencies..."
$NPM install --with-dev

# as we are collecting assets from various vendor/ composer modules
# we also need to install possible assets-build dependencies from those
# modules
for i in `find vendor/ -name 'package.json' | egrep 'assets/(Zed|Yves)/package.json'`; do
  cd `dirname $i`
  $NPM install
  cd $WORKDIR
done
