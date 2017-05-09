#!/bin/sh

# specify alpinelinux packages via those variables (you may define them in your build.conf)
# NPM_BUILD_DEPENDENCIES will be deleted after the `npm install` command is finished
# NPM_DEPENDENCIES will remain on the system
NPM_BUILD_DEPENDENCIES=${NPM_BUILD_DEPENDENCIES:-}
NPM_DEPENDENCIES=${NPM_DEPENDENCIES:-}


if [ ! -z "$NPM_DEPENDENCIES" ]; then
  $apk_add --virtual npm_dependencies $NPM_DEPENDENCIES
fi

if [ ! -z "$NPM_BUILD_DEPENDENCIES" ]; then
  $apk_add --virtual npm_build_dependencies $NPM_BUILD_DEPENDENCIES
fi


# install dependencies for building asset
# --with-dev is required to install spryker/oryx (works behind npm run x)
sectionNote "install required NPM dependencies..."
$NPM install --with-dev

# as we are collecting assets from various vendor/ composer modules
# we also need to install possible assets-build dependencies from those
# modules
for i in `find vendor/ -name 'package.json' | egrep 'assets/(Zed|Yves)/package.json'`; do
  sectionNote "handle $i"
  cd `dirname $i`
  $NPM install
  cd $WORKDIR
done


if [ ! -z "$NPM_BUILD_DEPENDENCIES" ]; then
  apk del npm_build_dependencies
fi
