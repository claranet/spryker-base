#!/bin/sh

# specify alpinelinux packages via this variable (you may define it in your build.conf)
# NPM_DEPENDENCIES will remain on the system if DEV_TOOLS=on, else they will be dropped
# after the build finished.
NPM_DEPENDENCIES=${NPM_DEPENDENCIES:-}


if [ ! -z "$NPM_DEPENDENCIES" ]; then
  install_packages --build $NPM_DEPENDENCIES
fi


# install dependencies for building asset
# --with-dev is required to install spryker/oryx (works behind npm run x)
sectionText "Installing required NPM dependencies"
$NPM install --with-dev

# as we are collecting assets from various vendor/ composer modules
# we also need to install possible assets-build dependencies from those
# modules
for i in `find vendor/ -name 'package.json' | egrep 'assets/(Zed|Yves)/package.json'`; do
  sectionText "Handle $i"
  cd `dirname $i`
  $NPM install
  cd $WORKDIR
done
